defmodule Prelude.Etude.Node.Function do
  use Prelude.Etude.Node

  def exit({:function, _line, name, arity, clauses}, %{public?: true} = state) do
    {
      [compile_public_entry(name, arity)],
      {[compile_etude_clause(name, arity, clauses, state)],
       []}
    }
  end
  def exit({:function, _line, name, arity, clauses}, state) do
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
    {:clause, -1, [escape(name), escape(arity), etude_dispatch], [],
      calls ++ [compile_etude_thunk(clauses, state)]}
  end

  defp compile_etude_thunk(clauses, %{function: {function, arity}}) do
    function = {:named_fun, -1, :"_#{function}/#{arity}", clauses}
    thunk = escape(__MODULE__.Thunk)
    ~S"""
    #{'__struct__' => unquote(thunk),
      arguments => [],
      function => unquote(function)}
    """
    |> erl(-1)
  end

  defp compile_public_etude_call(name, arity) do
    name = escape(name)
    arity = escape(arity)
    ~S"""
    '__etude__'(unquote(name), unquote(arity), 'Elixir.Etude.Dispatch':from_process())
    """
    |> erl(-1)
  end

  defp compile_calls(%{calls: calls}) do
    Enum.map(calls, fn({{module, function, arity}, fn_alias}) ->
      {:match, -1, fn_alias, compile_dispatch_lookup(module, function, arity)}
    end)
  end

  defp compile_local_calls(%{local_calls: calls}) do
    Enum.map(calls, fn({{function, arity}, fn_alias}) ->
      function = escape(function)
      arity = escape(arity)
      ~S"""
      unquote(fn_alias) =
        '__etude_local__'(unquote(function), unquote(arity), unquote(etude_dispatch))
      """
      |> erl(-1)
    end)
  end

  defp compile_dispatch_lookup(module, function, arity) do
    module = escape(module)
    function = escape(function)
    arity = escape(arity)
    ~S"""
    apply(unquote(etude_dispatch), resolve, [
      unquote(module),
      unquote(function),
      unquote(arity)
    ])
    """
    |> erl(-1)
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
