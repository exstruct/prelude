defmodule Prelude.Tracker do
  defmodule Op do
    defstruct [op: nil,
               registers: %{},
               stack: %{},
               heap: %{}]

    defimpl Inspect do
      def inspect(%{op: op, registers: r}, opts) do
        @protocol.inspect(r, opts)
      end
    end
  end

  defmodule Argument do
    defstruct [:fun, :arity, :pos]
  end

  defmodule LocalCall do
    defstruct [:fun, :arity, :args]
  end

  defmodule Transform do
    defstruct [:input, :fun]
  end

  defmodule Fun do
    defstruct [:fun, :arity, :env]
  end

  @pending [Argument, LocalCall, Transform]

  defmacro maybe?(v) do
    quote do
      %{__struct__: s} = unquote(v) when s in unquote(@pending)
    end
  end

  @safe_types [:atom, :float, :integer, :literal, :list]

  def track(module = %{code: code} = m) do
    code = Enum.map(code, &function(&1, module))
    %{module | code: code}
  end

  def function({:function, name, arity, entry, code} = fun, %{exports: exports}) do
    state = %{
      registers: %{},
      stack: %{},
      heap: %{},
      cache: %{},
      calls: %{},
      jumps: %{}
    } |> put_arguments(name, arity)

    {ex, labels} = gather_labels(code)

    state = Map.put(state, :labels, labels)

    jump(state, entry)
    |> elem(1)
    |> Map.get(:cache)
    |> Enum.each(fn({lbl, ops}) ->
      IO.puts "=== #{lbl} === "
      Enum.each(ops, &IO.inspect/1)
    end)
    IO.puts ""

    {:function, name, arity, entry, code}
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
    case Map.fetch(cache, l) do
      {:ok, ops} ->
        {ops, state}
      :error ->
        case Map.fetch(labels, l) do
          {:ok, ops} ->
            {ops, %{cache: cache} = state} = execute(ops, [], state)
            {ops, %{state | cache: Map.put(cache, l, ops)}}
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

    state = put_value(state, to, :erlang.make_tuple(size, nil))

    state = elements
    |> Stream.with_index()
    |> Enum.reduce(state, fn({{:put, from}, i}, state) ->
      tuple = get_value(state, to)
      value = get_value(state, from)
      tuple = put_elem(tuple, i, value)
      put_value(state, to, tuple)
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

  defp update_state({:bif, :element, _, args, tuple}, state) do
    # TODO
    state
  end
  defp update_state({:bif, :hd, _, [to], list}, state) do
    case get_value(state, list) do
      [hd | _] ->
        put_value(state, to, hd)
      value ->
        put_value(state, to, %Transform{input: value, fun: &:erlang.hd/1})
    end
  end

  ### Tests

  defp update_state({:test, _call, {:f, fail}, _args}, state) do
    {_, state} = jump(state, fail)
    state
  end

  ### Indexing & jumping

  defp update_state({:jump, {:f, l}}, state) do
    {_, state} = jump(state, l)
    state
  end

  ### Moving, extracting, modifying

  defp update_state({:move, from, to}, state) do
    value = get_value(state, from)
    put_value(state, to, value)
  end
  defp update_state({:get_list, list, h_to, t_to}, state) do
    case get_value(state, list) do
      [h | t] ->
        state
        |> put_value(h_to, h)
        |> put_value(t_to, t)
      value ->
        state
        |> put_value(h_to, %Transform{input: value, fun: &:erlang.hd/1})
        |> put_value(t_to, %Transform{input: value, fun: &:erlang.tl/1})
    end
  end
  defp update_state({:get_tuple_element, from, idx, to}, state) do
    case get_value(state, from) do
      t when is_tuple(t) ->
        put_value(state, to, elem(t, idx))
      value ->
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
        value = %LocalCall{fun: fun, arity: arity, args: env ++ args}
        put_register(state, 0, value)
    end
  end

  ### Fun construction
  defp update_state({:make_fun2, {_m, f, a}, _id, _uniq, capture}, state) do
    env = arity_range(capture) |> Enum.map(&get_register(state, &1))
    value = %Fun{fun: f, arity: a, env: env}
    put_register(state, 0, value)
  end

  ### R17

  defp update_state({:put_map_assoc, _, from, to, _, elements}, state) do
    case get_value(state, from) do
      maybe?(s) ->
        # TODO
        state
      map when is_map(map) ->
        map = assoc_map_elements(elements, map, state, fn(k, v, acc) ->
        Map.put(acc, k, v)
      end)
        put_value(state, to, map)
    end
  end
  defp update_state({:get_map_elements, {:f, fail}, from, elements}, state) do
    {_, state} = jump(state, fail)
    case get_value(state, from) do
      maybe?(s) ->
        put_map_elements(elements, state, fn(key) ->
          %Transform{input: s, fun: &:maps.get(&1, key)}
        end)
      map when is_map(map) ->
        put_map_elements(elements, state, fn(key) ->
          {:ok, value} = Map.fetch(map, key)
          value
        end)
    end
  end

  defp update_state(other, state) do
    state
  end

  defp assoc_map_elements(elements, acc, state, update) do
    case get_value(state, elements) do
      # TODO
      # maybe?(s) ->
      elements when is_list(elements) ->
        pair_reduce(elements, acc, fn(k, from, acc) ->
          case get_value(state, k) do
            maybe?(s) ->
              # TODO
              acc
            key ->
              value = get_value(state, from)
              update.(key, value, acc)
          end
        end)
    end
  end

  defp put_map_elements(elements, state, fetch) do
    case get_value(state, elements) do
      # TODO
      # maybe?(s) ->
      elements when is_list(elements) ->
        pair_reduce(elements, state, fn(k, to, state) ->
          case get_value(state, k) do
            maybe?(s) ->
              value = %Transform{input: s, fun: fetch}
              put_value(state, to, value)
            key ->
              put_value(state, to, fetch.(key))
          end
        end)
    end
  end

  defp new(op, %{registers: r, stack: s, heap: h} = state) do
    %__MODULE__.Op{op: op, registers: r, stack: s, heap: h}
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

  defp get_register(%{registers: registers}, register) do
    {:ok, value} = Map.fetch(registers, register)
    value
  rescue
    MatchError ->
      throw {:undefined_register, register}
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
    value
  end
  defp get_value(_, nil) do
    []
  end

  defp put_value(state, {:x, n}, value) do
    put_register(state, n, value)
  end
  defp put_value(state, {:y, n}, value) do
    put_stack(state, n, value)
  end

  defp put_call(%{calls: calls} = state, fun, arity, args) do
    calls = Map.update(calls, {fun, arity}, [args], &[args | &1])
    %{state | calls: calls}
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
  defp pair_reduce([], acc, fun) do
    acc
  end
  defp pair_reduce([a, b | list], acc, fun) do
    acc = fun.(a, b, acc)
    pair_reduce(list, acc, fun)
  end

  # defp pair_map(list, fun) do
  #   pair_reduce(list, [], fn(a, b, acc) ->
  #     [fun.(a, b) | acc]
  #   end)
  #   |> :lists.reverse()
  # end
end
