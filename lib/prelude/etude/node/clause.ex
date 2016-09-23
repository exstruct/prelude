defmodule Prelude.Etude.Node.Clause do
  use Prelude.Etude.Node

  def enter(node, state) do
    state = State.scope_enter(state)
    {node, state}
  end

  def exit({:clause, _, [], _, _} = node, state) do
    state = State.scope_exit(state)
    {node, state}
  end
  def exit({:clause, line, patterns, guards, body}, state) do
    state = State.scope_exit(state)

    {pattern, pattern_vars} = patterns
    |> Enum.map_reduce(MapSet.new(), fn(pattern, acc) ->
      compile_pattern(pattern, acc)
    end)
    {guard, {guard_vars, state}} = compile_guards(guards, state)

    {arity, pattern} = maybe_wrap_pattern(pattern)

    match = ~S"""
    'Elixir.Etude.Match':compile(unquote(pattern), unquote(guard))
    """
    |> erl(-1)
    |> compile_match()

    {match_var, state} = State.put_match(state, match)

    body = format_body(pattern_vars, body)

    used_vars = MapSet.union(pattern_vars, guard_vars)

    scope_vars = State.scope_vars(state)
    scope_intersection = MapSet.intersection(scope_vars, used_vars)
    scope = {:map, line, for name <- scope_intersection do
                           {:map_field_assoc, line, escape(name), {:var, line, name}}
                         end}

    {{:etude_clause, line, arity, match_var, scope, body}, state}
  end

  defp maybe_wrap_pattern([pattern]) do
    {1, pattern}
  end
  defp maybe_wrap_pattern(patterns) do
    {length(patterns), {:tuple, -1, patterns}}
  end

  defp format_body(vars, body) do
    body = for var <- vars do
      {:match, -1, {:var, -1, :_}, {:var, -1, var}}
    end ++ body

    bindings = cond do
      map_size(vars) > 0 ->
        {:map, -1, for var <- vars do
              {:map_field_exact, -1, {:atom, -1, var}, {:var, -1, var}}
            end}
      true ->
        {:var, -1, :_}
    end

    clause = {:clause, -1, [bindings], [], body}
    {:fun, -1, {:clauses, [clause]}}
  end

  def combine_clauses(clauses, line, %{module: m, function: {f, a}} = state) do
    {matches, arity} = clauses
    |> Enum.map_reduce(1, fn
      ({:etude_clause, l, arity, match, scope, body}, _) ->
        {{:tuple, l, [match, scope, body]}, arity}
      ({:clause, _, patterns, _, _} = clause, _) ->
        {clause, length(patterns)}
    end)

    if arity == 0, do: throw :zero_arity

    matches = cons(matches)
    {val_var, state} = State.gensym(state)

    location = {m, f, a, [line: line, file: "TODO"]} |> escape(line)

    match = ~S"""
    'Elixir.Etude.Future':location(
      'Elixir.Etude.Future':match_cases(unquote(val_var), unquote(matches)),
      unquote(location)
    )
    """
    |> erl(-1)

    {clause, state} = gen_clause(arity, val_var, match, state)

    {[clause], state}
  catch
    _, :zero_arity ->
      {clauses, state}
  end

  defp gen_clause(1, val_var, match, state) do
    clause = {:clause, -1, [val_var], [], [match]}
    {clause, state}
  end
  defp gen_clause(arity, val_var, match, state) do
    {vars, state} = 1..arity |> Enum.map_reduce(state, fn(_, s) -> State.gensym(s) end)
    t = {:tuple, -1, vars}
    clause = {:clause, -1, vars, [], [{:match, -1, val_var, t}, match]}
    {clause, state}
  end

  defp compile_pattern(pattern, acc) do
    Prelude.ErlSyntax.postwalk(pattern, acc, fn
      ({:var, _, :_} = var, acc) ->
        binding = make_binding(var)
        {binding, acc}
      ({:var, _, name} = var, acc) ->
        binding = make_binding(var)
        {binding, MapSet.put(acc, name)}
      ({:map_field_exact, _, _, _} = field, acc) ->
        {put_elem(field, 0, :map_field_assoc), acc}
      ({:match, _, lhs, rhs}, acc) ->
        {lhs, acc} = compile_pattern(lhs, acc)
        node = ~S"""
        'Elixir.Etude.Match':union(unquote(lhs), unquote(rhs))
        """
        |> erl(-1)
        {node, acc}
      (node, acc) ->
        {node, acc}
    end)
  end

  defp compile_guards([], state) do
    {escape(nil, -1), {MapSet.new(), state}}
  end
  defp compile_guards([[guard]], state) do
    compile_guards(guard, state)
  end
  defp compile_guards(guards, state) do
    Prelude.ErlSyntax.postwalk(guards, {MapSet.new(), state}, fn
      ({:call, line, {:remote, _, {:atom, _, :erlang}, name}, args}, acc) ->
        args = cons(args)
        call = ~S"""
        #{'__struct__' => 'Elixir.Etude.Match.Call',
          'fun' => unquote(name),
          args => unquote(args)}
        """
        |> erl(line)
        {call, acc}
      ({:op, line, name, arg}, acc) ->
        name = escape(name, line)
        call = ~S"""
        #{'__struct__' => 'Elixir.Etude.Match.Call',
          'fun' => unquote(name),
          args => [unquote(arg)]}
        """
        |> erl(line)
        {call, acc}
      ({:op, line, name, lhs, rhs}, acc) ->
        name = escape(name, line)
        call = ~S"""
        #{'__struct__' => 'Elixir.Etude.Match.Call',
          'fun' => unquote(name),
          args => [unquote(lhs), unquote(rhs)]}
        """
        |> erl(line)
        {call, acc}
      ({:var, _, name} = var, {vars, state}) ->
        binding = make_binding(var)
        vars = MapSet.put(vars, name)
        {binding, {vars, state}}
      (other, acc) ->
        {other, acc}
    end)
  end
end
