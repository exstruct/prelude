defmodule Prelude.Etude.Node.Case do
  use Prelude.Etude.Node

  def exit({:case, line, value, clauses}, state) do
    {clauses, state} = Enum.map_reduce(clauses, state, &compile_clause/2)
    # TODO add the compiled clauses to the top of the function

    {val_var, state} = State.gensym(state)

    {chain, state} = clauses
    |> :lists.reverse()
    |> Enum.reduce({nil, state}, fn(clause, {child, state}) ->
      compile_chain(clause, val_var, child, state)
    end)

    node = ~S"""
    begin
      unquote(val_var) = unquote(value),
      unquote(chain)
    end
    """
    |> erl(line)

    {node, state}
  end

  defp compile_chain({match, body, scope}, value, nil, state) do
    node = ~S"""
    'Elixir.Etude.Future':chain(
      (unquote(match))(unquote(value), unquote(scope)),
      unquote(body)
    )
    """
    |> erl(-1)
    {node, state}
  end
  defp compile_chain({match, body, scope}, value, child, state) do
    {tmp, state} = State.gensym(state)
    node = ~S"""
    'Elixir.Etude.Future':bichain(
      (unquote(match))(unquote(value), unquote(scope)),
      fun
        (#{'__struct__' := unquote(tmp)}) when (unquote(tmp) == 'Elixir.MatchError')
                                        orelse (unquote(tmp) == 'Elixir.CaseClauseError') ->
          unquote(child);
        (unquote(tmp)) ->
          'Elixir.Etude.Future':reject(unquote(tmp))
      end,
      unquote(body)
    )
    """
    |> erl(-1)
    {node, state}
  end

  defp compile_clause({:clause, line, patterns, guards, body}, state) do
    {pattern, vars} = compile_pattern(patterns)
    {guard, state} = compile_guards(guards, state)
    {bindings_pass, state} = State.gensym(state)

    match = ~S"""
    'Elixir.Etude.Match':compile(unquote(pattern), unquote(guard),
      #{'__struct__' => 'Elixir.Etude.Match.Scope',
        'fun' => fun(unquote(bindings_pass)) -> unquote(bindings_pass) end}
    )
    """
    |> erl(line)

    {body, state} = Prelude.Etude.Node.Block.exit({:block, line, body}, state)

    bindings = cond do
      map_size(vars) > 0 ->
        {:map, line, for {name, var} <- vars do
              {:map_field_exact, line, name, var}
            end}
      true ->
        {:var, line, :_}
    end

    body = ~S"""
    fun(unquote(bindings)) ->
      unquote(body)
    end
    """
    |> erl(line)

    # TODO look at the existing variables in the scope to figure out what we pass
    scope = ~S"""
    #{}
    """
    |> erl(line)

    {{match, body, scope}, state}
  end

  defp compile_pattern([pattern]) do
    compile_pattern(pattern)
  end
  defp compile_pattern(patterns) when is_list(patterns) do
    patterns = patterns |> Enum.map(&compile_pattern/1) |> cons()
    ~S"""
    #{'__struct__' => 'Elixir.Etude.Match.Union',
      patterns => unquote(patterns)}
    """
    |> erl(-1)
  end
  defp compile_pattern(pattern) do
    Prelude.ErlSyntax.postwalk(pattern, %{}, fn
      ({:var, _, :_} = var, acc) ->
        binding = make_binding(var)
        {binding, acc}
      ({:var, line, name} = var, acc) ->
        name = escape(name, line)
        binding = make_binding(var)
        {binding, Map.put(acc, name, var)}
      ({:map_field_exact, _, _, _} = field, acc) ->
        {put_elem(field, 0, :map_field_assoc), acc}
      (node, acc) ->
        {node, acc}
    end)
  end

  defp compile_guards([], state) do
    {escape(nil, -1), state}
  end
  defp compile_guards([[guard]], state) do
    compile_guards(guard, state)
  end
  defp compile_guards(guards, state) do
    Prelude.ErlSyntax.postwalk(guards, state, fn
      ({:call, line, {:remote, _, {:atom, _, :erlang}, name}, args}, state) ->
        args = cons(args)
        call = ~S"""
        #{'__struct__' => 'Elixir.Etude.Match.Call',
          'fun' => unquote(name),
          args => unquote(args)}
        """
        |> erl(line)
        {call, state}
      ({:op, line, name, lhs, rhs}, state) ->
        name = escape(name, line)
        call = ~S"""
        #{'__struct__' => 'Elixir.Etude.Match.Call',
          'fun' => unquote(name),
          args => [unquote(lhs), unquote(rhs)]}
        """
        |> erl(line)
        {call, state}
      ({:var, _, _} = var, state) ->
        binding = make_binding(var)
        {binding, state}
      (other, state) ->
        {other, state}
    end)
  end
end
