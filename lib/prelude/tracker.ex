defmodule Prelude.Tracker do
  defmodule Op do
    defstruct [op: nil,
               registers: %{},
               stack: %{},
               info: %{}]
  end

  defmodule Argument do
    defstruct [:fun, :arity, :pos]
  end

  defmodule ExtCall do
    defstruct [:module, :fun, :arity, :args]
  end

  defmodule LocalCall do
    defstruct [:fun, :arity, :args]
  end

  defmodule Transform do
    defstruct [:input, :fun]
  end

  defmodule Type do
    defstruct [:type]
  end

  defmodule Not do
    defstruct [:type]
  end

  defmodule Fun do
    defstruct [:fun, :arity, :env]
  end

  defmodule Literal do
    defstruct [:value]
  end

  defmodule PartialMap do
    defstruct [literal: %{}, elements: []]
  end

  @pending [Argument, ExtCall, LocalCall, Transform, Type, Not]
  @internal [Fun, Literal, PartialMap | @pending]

  defmacro maybe?(v) do
    quote do
      %{__struct__: s} = unquote(v) when s in unquote(@pending)
    end
  end

  @safe_types [:atom, :float, :integer, :literal, :list]

  def track(%{code: code} = module) do
    code = Enum.map(code, &function(&1, module))

    calls = Enum.reduce(code, %{}, fn(%{calls: calls}, acc) ->
      Map.merge(acc, calls, fn(_, v1, v2) ->
        MapSet.union(v1, v2)
      end)
    end)

    code = Enum.map(code, fn(%{name: name, arity: arity} = f) ->
      %{f | calls: Map.get(calls, {name, arity}, MapSet.new())}
    end)

    %{module | typed_code: code}
  end

  def function({:function, name, arity, entry, code}, _module) do
    state = %{
      registers: %{},
      stack: %{},
      cache: %{},
      calls: %{},
      jumps: %{},
      label: nil
    } |> put_arguments(name, arity)

    {ex, labels} = gather_labels(code)

    state = Map.put(state, :labels, labels)

    {ex, state} = execute(ex, [], state)

    state = jump(state, entry)

    code = state |> Map.get(:cache)
    code = code |> Map.put(:__before__, ex)

    %{
      name: name,
      arity: arity,
      entry: entry,
      code: code,
      calls: state.calls,
      jumps: state.jumps
    }
  end

  defp gather_labels(code) do
    {_, ex, acc} = code
    |> Enum.reduce({nil, [], %{}}, fn
      ({:label, l}, {_, ex, acc}) ->
        {l, ex, Map.put(acc, l, [])}
      (op, {nil, extras, acc}) ->
        {nil, [op | extras], acc}
      (op, {l, ex, acc}) ->
        {l, ex, Map.update(acc, l, nil, &[op | &1])}
    end)

    acc = acc
    |> Stream.map(fn({l, ops}) ->
      {l, :lists.reverse(ops)}
    end)
    |> Enum.into(%{})

    {:lists.reverse(ex), acc}
  end

  defp jump(%{cache: cache, labels: labels} = state, l) do
    # TODO handle cyclical jumps
    # TODO cache based on the stack and registers so we can have the different jump typings
    case Map.fetch(cache, l) do
      {:ok, _} ->
        state
      :error ->
        case Map.fetch(labels, l) do
          {:ok, ops} ->
            prev = state.label
            state = Map.put(state, :label, l)
            {ops, %{cache: cache} = state} = execute(ops, [], state)
            %{state | cache: Map.put(cache, l, ops), label: prev}
          :error ->
            throw {:label_not_found, l}
        end
    end
  end

  defp execute([], acc, state) do
    {:lists.reverse(acc), state}
  end
  defp execute([{:put_tuple, size, to} = op | ops], acc, state) do
    struct = new(op, state)
    {elements, ops} = consume(ops, size)

    state = put_value(state, to, %Literal{value: :erlang.make_tuple(size, nil)})

    state = elements
    |> Stream.with_index()
    |> Enum.reduce(state, fn({{:put, from}, i}, state) ->
      %Literal{value: tuple} = get_value(state, to)
      value = get_value(state, from)
      tuple = put_elem(tuple, i, value)
      put_value(state, to, %Literal{value: tuple})
    end)

    execute(ops, [struct | acc], state)
  end
  defp execute([op | ops], acc, state) do
    struct = new(op, state)
    state = update_state(op, state)
    execute(ops, [struct | acc], state)
  end

  ### Function and BIF calls

  defp update_state({call, _, {_mod, fun, arity}}, state) when call in [:call, :call_only] do
    args = arity_range(arity) |> Enum.map(&get_register(state, &1))
    state = put_call(state, fun, arity, args)
    put_register(state, 0, %LocalCall{fun: fun, arity: arity, args: args})
  end

  defp update_state({:call_ext, arity, {:extfunc, module, fun, arity}}, state) do
    args = arity_range(arity) |> Enum.map(&get_register(state, &1))
    put_register(state, 0, %ExtCall{module: module, fun: fun, arity: arity, args: args})
  end

  defp update_state({:bif, :element, _, _args, _tuple}, state) do
    # TODO
    state
  end
  defp update_state({:bif, :hd, _, [to], list}, state) do
    case get_value(state, list) do
      %Literal{value: [hd | _]} ->
        put_value(state, to, hd)
      maybe?(value) ->
        put_value(state, to, %Transform{input: value, fun: &:erlang.hd/1})
    end
  end

  ### Tests

  defp update_state({:test, :bs_start_match2, {:f, fail}, [_subj, _, _, to]}, state) do
    state = jump(state, fail)
    put_value(state, to, %Type{type: :binary})
  end
  defp update_state({:test, :bs_get_integer2, {:f, fail}, [_subj, _, _, _, _field_flags, to]}, state) do
    state = jump(state, fail)
    put_value(state, to, %Type{type: :integer})
  end
  defp update_state({:test, call, {:f, fail}, [arg]}, state) do
    # TODO Add %Not{type: type} for the fail case
    state = jump(state, fail)
    case get_value(state, arg) do
      %Literal{value: value} ->
        type = call_test(call, value)
        put_value(state, arg, type)
      maybe?(value) ->
        value = %Transform{
          input: value,
          fun: &call_test(call, &1)
        }
        put_value(state, arg, value)
    end
  end

  ### Indexing & jumping

  defp update_state({:jump, {:f, l}}, state) do
    jump(state, l)
  end

  ### Moving, extracting, modifying

  defp update_state({:move, from, to}, state) do
    value = get_value(state, from)
    put_value(state, to, value)
  end
  defp update_state({:get_list, list, h_to, t_to}, state) do
    case get_value(state, list) do
      %Literal{value: [h | t]} when is_list(t) ->
        state
        |> put_value(h_to, h)
        |> put_value(t_to, %Literal{value: t})
      %Literal{value: [h | t]} ->
        state
        |> put_value(h_to, h)
        |> put_value(t_to, t)
      maybe?(value) ->
        # TODO wrap hd and tl so we can handle unknown cases
        state
        |> put_value(h_to, %Transform{input: value, fun: &:erlang.hd/1})
        |> put_value(t_to, %Transform{input: value, fun: &:erlang.tl/1})
    end
  end
  defp update_state({:get_tuple_element, from, idx, to}, state) do
    case get_value(state, from) do
      %Literal{value: t} when is_tuple(t) ->
        put_value(state, to, elem(t, idx))
      maybe?(value) ->
        # TODO wrap elem so we can handle unknown cases
        put_value(state, to, %Transform{input: value, fun: &elem(&1, idx)})
    end
  end

  ### Building terms
  # put_tuple/2 and put/2 are defined in execute/3
  defp update_state({:put_list, from, list, to}, state) do
    v = get_value(state, from)
    list = get_value(state, list)
    put_value(state, to, [v | list])
  end

  ### Fun support

  defp update_state({:call_fun, arity}, state) do
    args = arity_range(arity) |> Enum.map(&get_register(state, &1))
    case get_register(state, arity) do
      %Fun{fun: fun, arity: arity, env: env} ->
        args = env ++ args
        state = put_call(state, fun, arity, args)
        value = %LocalCall{fun: fun, arity: arity, args: args}
        put_register(state, 0, value)
      # TODO handle other cases
    end
  end

  ### Fun construction
  defp update_state({:make_fun2, {_m, f, a}, _id, _uniq, capture}, state) do
    env = arity_range(capture) |> Enum.map(&get_register(state, &1))
    value = %Fun{fun: f, arity: a, env: env}
    put_register(state, 0, value)
  end

  defp update_state({:bs_append, _, _input, _, _, _, _from, _field_flags, to}, state) do
    # TODO add better tracking
    value = %Type{type: :binary}
    put_value(state, to, value)
  end

  ### R17

  defp update_state({:put_map_assoc, _, from, to, _, elements}, state) do
    case get_value(state, from) do
      %Literal{value: map} when is_map(map) ->
        map = assoc_map_elements(elements, map, state, fn(k, v, acc) ->
          Map.put(acc, k, v)
        end)
        put_value(state, to, map)
      maybe?(_) ->
        # TODO
        state
    end
  end
  defp update_state({:get_map_elements, {:f, fail}, from, elements} = op, state) do
    state = jump(state, fail)
    case get_value(state, from) do
      %Literal{value: map} when is_map(map) ->
        put_map_elements(elements, state, fn(key) ->
          {:ok, value} = Map.fetch(map, key)
          value
        end)
      maybe?(s) ->
        put_map_elements(elements, state, fn(key) ->
          %Transform{input: s, fun: &:maps.get(&1, key)}
        end)
    end
  end

  defp update_state(_other, state) do
    state
  end

  for call <- [:is_atom, :is_binary, :is_bitstring, :is_boolean, :is_float, :is_function,
               :is_integer, :is_list, :is_map, :is_number, :is_pid, :is_port, :is_reference,
               :is_tuple] do
    type = call |> to_string() |> String.trim_leading("is_") |> String.to_atom()
    defp call_test(unquote(call), value) when unquote(call)(value) do
      value
    end
    defp call_test(unquote(call), _) do
      %Type{type: unquote(type)}
    end
  end
  defp call_test(:is_nonempty_list, [_ | _] = l) do
    l
  end
  defp call_test(:is_nonempty_list, _) do
    %Type{type: :list}
  end
  defp call_test(:is_nil, []) do
    []
  end
  defp call_test(:is_nil, _) do
    %Type{type: :list}
  end

  defp assoc_map_elements(elements, acc, state, update) do
    case get_value(state, elements) do
      %Literal{value: elements} when is_list(elements) ->
        pm = pair_reduce(elements, %PartialMap{literal: acc}, fn(k, from, %PartialMap{literal: l, elements: e} = m) ->
          case get_value(state, k) do
            %Literal{value: key} ->
              value = get_value(state, from)
              %{m | literal: update.(key, value, l)}
            maybe?(s) ->
              value = get_value(state, from)
              %{m | elements: [{s, value} | e]}
          end
        end)
        case pm do
          %{elements: [], literal: l} ->
            l
          _ ->
            pm
        end
    end
  end

  defp put_map_elements(elements, state, fetch) do
    case get_value(state, elements) do
      %Literal{value: elements} when is_list(elements) ->
        pair_reduce(elements, state, fn(k, to, state) ->
          case get_value(state, k) do
            %Literal{value: key} ->
              put_value(state, to, fetch.(key))
            maybe?(s) ->
              value = %Transform{input: s, fun: fetch}
              put_value(state, to, value)
          end
        end)
    end
  end

  defp new(op, %{registers: r, stack: s}) do
    %__MODULE__.Op{op: op, registers: r, stack: s}
  end

  defp put_arguments(state, f, a) do
    arity_range(a)
    |> Enum.reduce(state, fn(i, state) ->
      put_register(state, i, %Argument{fun: f, arity: a, pos: i})
    end)
  end

  defp put_register(%{registers: registers} = state, register, value) do
    %{state | registers: Map.put(registers, register, value)}
  end

  defp get_register(%{registers: registers, label: l}, register) do
    {:ok, value} = Map.fetch(registers, register)
    value
  rescue
    MatchError ->
      throw {:undefined_register, register, {:label, l}}
  end

  defp put_stack(%{stack: stack} = state, n, value) do
    %{state | stack: Map.put(stack, n, value)}
  end

  defp get_stack(%{stack: stack}, n) do
    {:ok, value} = Map.fetch(stack, n)
    value
  end

  defp get_value(state, {:x, n}) do
    get_register(state, n)
  end
  defp get_value(state, {:y, n}) do
    get_stack(state, n)
  end
  defp get_value(_, {type, value}) when type in @safe_types do
    %Literal{value: value}
  end
  defp get_value(_, nil) do
    %Literal{value: []}
  end

  defp put_value(state, to, v) when is_binary(v) or is_list(v) or is_number(v) or is_tuple(v) do
    put_value_unsafe(state, to, %Literal{value: v})
  end
  defp put_value(state, to, map) when is_map(map) do
    put_value_unsafe(state, to, maybe_wrap_map(map))
  end
  defp put_value(state, to, value) do
    put_value_unsafe(state, to, value)
  end

  defp put_value_unsafe(state, {:x, n}, value) do
    put_register(state, n, value)
  end
  defp put_value_unsafe(state, {:y, n}, value) do
    put_stack(state, n, value)
  end

  defp maybe_wrap_map(map) do
    case map do
      %struct{} when struct in @internal ->
        map
      _ ->
        %Literal{value: map}
    end
  end

  defp put_call(%{calls: calls} = state, fun, arity, args) do
    key = {fun, arity}
    case Map.fetch(calls, key) do
      :error ->
        %{state | calls: Map.put(calls, key, MapSet.new([args]))}
      {:ok, prev} ->
        prev = MapSet.put(prev, args)
        %{state | calls: Map.put(calls, key, prev)}
    end
  end

  defp arity_range(0) do
    []
  end
  defp arity_range(num) do
    0..(num - 1)
  end

  defp consume(list, count, acc \\ [])
  defp consume(list, 0, acc) do
    {:lists.reverse(acc), list}
  end
  defp consume([h | t], count, acc) when count >= 1 do
    consume(t, count - 1, [h | acc])
  end

  defp pair_reduce(list, acc, fun)
  defp pair_reduce([], acc, _fun) do
    acc
  end
  defp pair_reduce([a, b | list], acc, fun) do
    acc = fun.(a, b, acc)
    pair_reduce(list, acc, fun)
  end
end
