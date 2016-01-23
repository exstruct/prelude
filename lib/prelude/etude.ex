defmodule Prelude.Etude do
  def compile(forms, _opts) do
    {exports, functions} = Enum.reduce(forms, {[], %{}}, &partition/2)

    initial_state = %{
      scopes: [],
      locals: Map.keys(functions),
      calls: %{}
    }

    functions
    |> Enum.reduce({[], [etude_default_clause()]}, &handle_function(&1, initial_state, &2))
    |> concat(exports)
    |> IO.inspect
  end

  defp partition({:function, _, name, arity, clauses}, {exports, funs}) do
    key = {name, arity}
    prev = Map.get(funs, key, [])
    {exports, Map.put(funs, key, prev ++ clauses)}
  end
  defp partition(other, {exports, funs}) do
    {[other | exports], funs}
  end

  defp handle_function({{name, arity}, clauses}, state, {functions, etudes}) do
    state = Map.merge(state, %{function: {name, arity}})
    {f, e} = Prelude.ErlSyntax.traverse({:function, -1, name, arity, clauses}, state, traverse(:enter), traverse(:exit))
    {[f | functions], [e | etudes]}
  end

  defp concat({functions, etudes}, exports) do
    Enum.reverse(exports) ++ functions ++ [{:function, 1, :__etude__, 3, etudes}]
  end

  defp etude_default_clause do
    {:clause, -1, [{:var, -1, :_}, {:var, -1, :_}, {:var, -1, :_}], [], [{:atom, -1, nil}]}
  end

  defp node_to_module(node) do
    mod = Module.concat(__MODULE__, node |> elem(0) |> :erlang.atom_to_binary(:utf8) |> Mix.Utils.camelize)
    mod.module_info()
    mod
  end

  defp traverse(name) do
    fn(node, acc) ->
      mod = node_to_module(node)
      cond do
        function_exported?(mod, name, 2) ->
          apply(mod, name, [node, acc])
        function_exported?(mod, name, 1) ->
          node = apply(mod, name, [node])
          {node, acc}
        true ->
          {node, acc}
      end
    end
  end
end
