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
    calls = compile_calls(state) ++ compile_local_calls(state)
    {:clause, -1, [escape(name), escape(arity), etude_dispatch], [],
      calls ++ [compile_etude_future(clauses, state)]}
  end

  defp compile_etude_future(clauses, %{function: {function, arity}} = state) do
    clauses = compile_function_clauses(clauses, state)
    function = {:named_fun, -1, :"_@@@#{function}___#{arity}", clauses}

    ~S"""
    'Elixir.Etude.Future':'of'(unquote(function))
    """
    |> erl(-1)
  end

  defp compile_function_clauses(clauses, %{function: {_, 0}}) do
    clauses
  end
  defp compile_function_clauses(clauses, %{function: {_, 1}} = state) do
    {var, state} = State.gensym(state)
    [
      {:clause, -1, [var], [], [
        {:case, -1, var, for {:clause, line, args, guards, body} <- clauses do
          {:clause, line, args, guards, body}
        end}
        |> Prelude.Etude.Node.Case.exit(state)
        |> elem(0)
      ]}
    ]
  end
  defp compile_function_clauses(clauses, %{function: {_, arity}} = state) do
    {vars, state} = 1..arity |> Enum.map_reduce(state, fn(_, s) -> State.gensym(s) end)
    [
      {:clause, -1, vars, [], [
        {:case, -1, {:tuple, -1, vars}, for {:clause, line, args, guards, body} <- clauses do
          {:clause, line, [{:tuple, -1, args}], guards, body}
        end}
        |> Prelude.Etude.Node.Case.exit(state)
        |> elem(0)
     ]}
    ]
  end

  defp compile_calls(%{calls: calls}) do
    Enum.map(calls, fn({{module, function, arity}, fn_alias}) ->
      {:match, -1, fn_alias, compile_dispatch_lookup(module, function, arity)}
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

  defp compile_dispatch_lookup(module, function, arity) do
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
