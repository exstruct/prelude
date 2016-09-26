defmodule Prelude.Transformer do
  @ignore [__info__: 1, __etude__: 0, module_info: 0, module_info: 1]

  @unsafe __MODULE__.UNSAFE
  @safe __MODULE__.SAFE

  import Prelude.Debugger, warn: false

  def transform(module = %{code: code} = m, opts) do
    state = %{
      module: module,
      function: nil,
      call: nil,
      registers: %{},
      dispatch: opts[:dispatch],
      label: max_label(code),
      location: 0,
      append: []
    }
    {code, state} = Enum.map_reduce(code, state, &function/2)
    code = code ++ state.append

    print(code)

    %{m | code: code, num_labels: state.label + 1}
  end

  def function({:function, name, arity, _, code} = fun, state) when {name, arity} in @ignore do
    {fun, state}
  end
  def function({:function, name, arity, entry, code} = fun, state) do
    state = %{state | function: {name, arity}}
    # TODO put the arity
    state = put_register(state, {:x, 0}, @unsafe)
    {code, state} = Enum.map_reduce(code, state, &handle/2)
    code = :lists.flatten(code)
    {{:function, name, arity, entry, code}, state}
  end

  defp handle({:line, _} = location, state) do
    {location, %{state | location: location}}
  end
  defp handle({:call_ext, _, _} = call, state) do
    {call, put_register(state, {:x, 0}, @unsafe)}
  end
  defp handle({:move, {:x, _} = from, to} = instr, state) do
    {:ok, value} = fetch_register(state, from)
    state = put_register(state, to, value)
    {instr, state}
  end
  defp handle({:move, value, register} = instr, state) do
    {instr, put_register(state, register, value)}
  end

  defp handle({:test, _test, _fail_label, registers} = t, state) do
    maybe_fork(registers, state, t)
  end

  defp handle(:return, state) do
    {:return, %{state | call: nil, registers: %{}}}
  end

  defp handle({:get_map_elements, fail_label, register, elements} = instr, state) do
    {:ok, value} = fetch_register(state, register)
    state =
      case elements do
        {:list, l} when value == @unsafe ->
          pair_reduce(l, state, fn(_, target, state) ->
            put_register(state, target, @unsafe)
          end)
      end

    {instr, state}
  end

  defp handle(other, state) do
    {other, state}
  end

  defp maybe_fork([register], state, instr) do
    case fetch_register(state, register) do
      {:ok, @unsafe} ->
        continuation(state, instr)
        # {instr, state}
    end
  end

  defp continuation(%{module: module, function: {n, a}} = state, instr) do
    # {{_, id} = label, state} = new_label(state)
    # name = :"-#{n}/#{a}-cont-#{id}-"
    # num_free = 0

    # {{_, fl_id} = fl, state} = new_label(state)

    asm = [
      # {:move, {:x, 0}, {:y, 0}},
      # {:make_fun2, {:f, fl_id}, 0, 0, num_free},

      {:put_map_assoc, {:f, 0}, {:literal, %{__struct__: Etude.Chain}}, {:x, 0}, 1,
        {:list, [
          {:atom, :future}, {:x, 0},
          {:atom, :on_ok}, {:x, 0}
        ]}},

      {:deallocate, 0},
      :return,
   ]

   # state =
   #   state
   #   |> append([
   #     {:function, name, 1, fl_id, [
   #         state.location,
   #         fl,
   #         instr,
   #         :return
   #         ## TODO prepare the stack for where we left off
   #         # {:jump, {:f, id}}
   #         # {:is_atom, {:f, id}, {:literal, 0}}
   #     ]}
   #   ])

    {asm, state}
  end

  defp fetch_register(%{registers: registers}, register) do
    Map.fetch(registers, register)
  end

  defp get_register(state, register, default \\ nil) do
    case fetch_register(state, register) do
      {:ok, value} ->
        value
      :error ->
        default
    end
  end

  defp put_register(%{registers: registers} = state, register, value) do
    %{state | registers: Map.put(registers, register, value)}
  end

  defp new_label(%{label: l} = state) do
    label = {:label, l + 1}
    {label, %{state | label: l + 1}}
  end

  defp pair_reduce([], acc, _fun) do
    acc
  end
  defp pair_reduce([a, b | rest], acc, fun) do
    acc = fun.(a, b, acc)
    pair_reduce(rest, acc, fun)
  end

  defp max_label(functions) do
    (functions
    |> List.last()
    |> elem(4)
    |> Enum.reduce(0, fn
      ({:label, l}, _) ->
        l
      (_, l) ->
        l
    end))
  end

  defp append(%{append: append} = state, instrs) do
    %{state | append: append ++ instrs}
  end

  defp debug_dump(%{registers: registers}) do
    :io.format('      -> ')
    IO.inspect registers, width: :infinity
  end
end
