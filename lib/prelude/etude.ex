defmodule Prelude.Etude do
  def compile(forms, _opts) do
    {attributes, exports, functions} = Enum.reduce(forms, {[], %{}, %{}}, &partition/2)

    initial_state = %Prelude.Etude.State{
      locals: Enum.reduce(functions, %{}, fn({key, _}, acc) -> Map.put(acc, key, true) end),
      exports: exports,
    }

    functions
    |> Enum.reduce({[], [], []}, &handle_function(&1, initial_state, &2))
    |> concat(attributes)
  end

  defp partition({:function, _, name, arity, clauses}, {attributes, exports, funs}) do
    key = {name, arity}
    prev = Map.get(funs, key, [])
    {attributes, exports, Map.put(funs, key, prev ++ clauses)}
  end
  defp partition({:attribute, _, :export, exported} = attr, {attributes, exports, funs}) do
    exports = Enum.reduce(exported, exports, fn
      ({:__struct__, 0}, acc) ->
        acc
      ({name, arity}, acc) ->
        Map.put(acc, {name, arity}, true)
    end)
    {[attr | attributes], exports, funs}
  end
  defp partition(other, {attributes, exports, funs}) do
    {[other | attributes], exports, funs}
  end

  defp handle_function({{:__struct__, 0}, clauses}, _state, {functions, public_etudes, private_etudes}) do
    function = {:function, -1, :__struct__, 0, clauses}
    {functions ++ [function],
     public_etudes,
     private_etudes}
  end
  defp handle_function({{name, arity}, clauses}, state, {functions, public_etudes, private_etudes}) do
    state = %{state | function: {name, arity},
                       public?: Map.has_key?(state.exports, {name, arity})}

    enter = Prelude.Etude.Node.traverse_fn(:enter)
    exit = Prelude.Etude.Node.traverse_fn(:exit)
    node = {:function, -1, name, arity, clauses}

    {additional_functions, {additional_public, additional_private}} = Prelude.ErlSyntax.traverse(node, state, enter, exit)

    {functions ++ additional_functions,
     public_etudes ++ additional_public,
     private_etudes ++ additional_private}
  end

  defp concat({functions, [], private_etudes}, attributes) do
    Enum.reverse(attributes)
    ++ functions
    ++ handle_etudes(:__etude_local__, private_etudes)
  end
  defp concat({functions, public_etudes, private_etudes}, attributes) do
    export_etudes(attributes)
    ++ functions
    ++ handle_etudes(:__etude__, public_etudes)
    ++ handle_etudes(:__etude_local__, private_etudes)
  end

  defp export_etudes(attributes) do
    [{:attribute, -1, :export, [__etude__: 3]} | attributes]
    |> Enum.reverse()
  end

  defp handle_etudes(_, []) do
    []
  end
  defp handle_etudes(:__etude__ = name, etudes) do
    [{:function, -1, name, 3, Enum.reverse([etude_default_clause | etudes])}]
  end
  defp handle_etudes(:__etude_local__ = name, etudes) do
    [{:function, -1, name, 3, Enum.reverse(etudes)}]
  end

  defp etude_default_clause do
    {:clause, -1, [{:var, -1, :_}, {:var, -1, :_}, {:var, -1, :_}], [], [{:atom, -1, nil}]}
  end
end
