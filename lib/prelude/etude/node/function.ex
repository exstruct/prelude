defmodule Prelude.Etude.Node.Function do
  use Prelude.Etude.Node

  def exit({:function, line, name, arity, clauses}, %{public?: true} = state) do
    {
      [compile_public_entry(name, arity)],
      {[compile_etude_clause(name, arity, clauses, state)],
       []}
    }
  end
  def exit({:function, line, name, arity, clauses}, state) do
    {
      [],
      {[],
       [compile_etude_clause(name, arity, clauses, state)]}
    }
  end

  defp compile_public_entry(name, arity) do
    {args, cons} = args(arity)

    etude = compile_public_etude_call(name, arity)

    {:function, -1, name, arity,
      [{:clause, -1, args, [],
        [put_arguments(etude, cons)]}]}
  end

  defp compile_etude_clause(name, arity, clauses, state) do
    calls = compile_calls(state) ++ compile_local_calls(state)
    {:clause, -1, [{:atom, -1, name}, {:integer, -1, arity}, etude_dispatch], [],
      calls ++ [compile_etude_thunk(clauses, state)]}
  end

  defp compile_etude_thunk(clauses, %{function: {function, arity}}) do
    fun = {:named_fun, -1, :"_#{function}/#{arity}", clauses}
    {:map, -1,
      [{:map_field_assoc, -1, {:atom, -1, :__struct__}, {:atom, -1, __MODULE__.Thunk}},
       {:map_field_assoc, -1, {:atom, -1, :arguments}, {:nil, -1}},
       {:map_field_assoc, -1, {:atom, -1, :function}, fun}]}
  end

  defp compile_public_etude_call(name, arity) do
    {:call, -1, {:atom, -1, :__etude__},
     [{:atom, -1, name}, {:integer, -1, arity},
      {:call, -1,
       {:remote, -1, {:atom, -1, Etude.Dispatch}, {:atom, -1, :from_process}},
       []}]}
  end

  defp compile_calls(%{calls: calls}) do
    Enum.map(calls, fn({{module, function, arity}, fn_alias}) ->
      {:match, -1, fn_alias, compile_dispatch_lookup(module, function, arity)}
    end)
  end

  defp compile_local_calls(%{local_calls: calls}) do
    Enum.map(calls, fn({{function, arity}, fn_alias}) ->
      {:match, -1, fn_alias,
        {:call, -1, {:atom, -1, :__etude_local__}, [
          {:atom, -1, function},
          {:integer, -1, arity},
          etude_dispatch
      ]}}
    end)
  end

  defp compile_dispatch_lookup(module, function, arity) do
    {:call, -1, {:remote, -1, etude_dispatch, {:atom, -1, :resolve}}, [
      {:atom, -1, module},
      {:atom, -1, function},
      {:integer, -1, arity}
    ]}
  end

  defp args(0) do
    {[], {nil, -1}}
  end
  defp args(arity) do
    {a, c} = args(arity - 1)
    var = {:var, -1, :"arg_#{arity}"}
    {[var | a], {:cons, -1, var, c}}
  end
end

defmodule Prelude.Etude.Node.Function.Thunk do
  defstruct arguments: [],
            function: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Function.Thunk do
  def resolve(%{function: function, arguments: arguments}, state) when is_function(function) do
    {apply(function, arguments), state}
  end
end
