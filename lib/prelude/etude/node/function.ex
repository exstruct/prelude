defmodule Prelude.Etude.Node.Function do
  use Prelude.Etude.Node

  def exit({:function, _line, name, arity, clauses}, %{public?: true} = state) do
    {[compile_etude_clause(name, arity, clauses, state)],
     []}
  end
  def exit({:function, _line, name, arity, clauses}, state) do
    {[],
     [compile_etude_clause(name, arity, clauses, state)]}
  end

  defp compile_etude_clause(name, arity, clauses, state) do
    {future, state} = compile_etude_future(clauses, state)
    calls = compile_calls(state) ++ compile_local_calls(state) ++ compile_matches(state)
    {:clause, -1, [escape(name), escape(arity), etude_dispatch], [],
      calls ++ [future]}
  end

  defp compile_etude_future(clauses, %{function: {function, arity}} = state) do
    {clauses, state} = Prelude.Etude.Node.Clause.combine_clauses(clauses, -1, state)
    function = {:named_fun, -1, :"_@@@#{function}___#{arity}", clauses}

    node = ~S"""
    'Elixir.Etude.Future':'of'(unquote(function))
    """
    |> erl(-1)
    {node, state}
  end

  defp compile_calls(%{calls: calls}) do
    Enum.map(calls, fn({{module, function, arity}, fn_alias}) ->
      {:match, -1, fn_alias, compile_dispatch_lookup(module, function, arity)}
    end)
  end

  defp compile_matches(%{matches: matches}) do
    Enum.map(matches, fn({match, var}) ->
      {:match, -1, var, match}
    end)
  end

  defp compile_local_calls(%{exports: exports, local_calls: calls}) do
    Enum.map(calls, fn({{function, arity}, fn_alias}) ->
      resolve = if Map.has_key?(exports, {function, arity}) do
        :__etude__
      else
        :__etude_local__
      end |> escape()

      {:match, -1, fn_alias,
       {:call, -1, resolve, [
           escape(function),
           escape(arity),
           etude_dispatch
         ]}}
    end)
  end

  def compile_dispatch_lookup(module, function, arity) do
    module = escape(module)
    function = escape(function)
    arity = escape(arity)
    ~S"""
    erlang:apply(unquote(etude_dispatch), resolve, [
      unquote(module),
      unquote(function),
      unquote(arity)
    ])
    """
    |> erl(-1)
  end
end
