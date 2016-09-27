defmodule Prelude.Transformer do
  @ignore [__info__: 1, __etude__: 0, module_info: 0, module_info: 1]

  @unsafe __MODULE__.UNSAFE
  @safe __MODULE__.SAFE

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

    %{m | code: code, num_labels: state.label + 1}
  end

  def function({:function, name, arity, _, code} = fun, state) when {name, arity} in @ignore do
    {fun, state}
  end
  def function({:function, name, arity, entry, code} = fun, state) do
    state = %{state | function: {name, arity}}
    {code, state} = Enum.map_reduce(code, state, &handle/2)
    code = :lists.flatten(code)
    {{:function, name, arity, entry, code}, state}
  end

  defp handle(other, state) do
    {other, state}
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
end
