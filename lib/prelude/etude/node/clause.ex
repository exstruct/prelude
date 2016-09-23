defmodule Prelude.Etude.Node.Clause do
  use Prelude.Etude.Node

  def enter({:clause, _, patterns, _, _} = node, state) do
    state = State.scope_enter(state)
    state = Enum.reduce(patterns, state, fn(pattern, state) ->
      {_, vars} = compile_pattern(pattern, MapSet.new())
      Enum.reduce(vars, state, &State.put_var(&2, &1))
    end)
    {node, state}
  end

  def exit({:clause, _, [], _, _} = node, state) do
    state = State.scope_exit(state)
    {node, state}
  end
  def exit({:clause, _, patterns, [], _} = clause, state) do
    state = State.scope_exit(state)
    all_vars = Enum.all?(patterns, &(elem(&1, 0) == :var))
    if all_vars do
      {clause, state}
    else
      compile_clause(clause, state)
    end
  end
  def exit(clause, state) do
    state = State.scope_exit(state)
    compile_clause(clause, state)
  end

  defp compile_clause({:clause, line, patterns, guards, body}, state) do
    {pattern, pattern_vars} = Enum.map_reduce(patterns, MapSet.new(), &compile_pattern/2)
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
    {matches, {arity, state}} = Enum.map_reduce(clauses, {nil, state}, &translate_clause/2)

    if arity == nil, do: throw :normal_clause
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
    _, :normal_clause ->
      {clauses, state}
  end

  defp translate_clause({:etude_clause, l, arity, match, scope, body}, {_, state}) do
    {{:tuple, l, [match, scope, body]}, {arity, state}}
  end
  defp translate_clause({:clause, _, _, _, _} = clause, {nil, state}) do
    {clause, {nil, state}}
  end
  defp translate_clause({:clause, _, _, _, _} = clause, {arity, state}) do
    {clause, state} = compile_clause(clause, state)
    translate_clause(clause, {arity, state})
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
        name = map_op(name)
        name = escape(name, line)
        call = ~S"""
        #{'__struct__' => 'Elixir.Etude.Match.Call',
          'fun' => unquote(name),
          args => [unquote(arg)]}
        """
        |> erl(line)
        {call, acc}
      ({:op, line, name, lhs, rhs}, acc) ->
        name = map_op(name)
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

  defp map_op(:andalso), do: :and
  defp map_op(:orelse), do: :or
  defp map_op(op), do: op
end
