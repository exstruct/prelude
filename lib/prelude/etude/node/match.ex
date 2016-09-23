defmodule Prelude.Etude.Node.Match do
  use Prelude.Etude.Node

  def exit({:match, _, m, m}, state) do
    if elixir_scoping?(m) do
      {{:atom, -1, nil}, state}
    else
      {m, state}
    end
  end
  def exit({:match, line, {:tuple, _, lhs}, {:tuple, _, rhs}}, state) when length(lhs) == length(rhs) do
    {exprs, state} = lhs
    |> Stream.zip(rhs)
    |> Enum.map_reduce(state, fn({l, r}, state) ->
      {:match, line, l, r}
      |> exit(state)
    end)
    {{:block, line, exprs}, state}
  end
  def exit({:match, _, {:var, _, var}, _} = node, state) do
    state = State.put_var(state, var)
    {node, state}
  end
  def exit({:match, line, lhs, rhs}, %{function: {f, a}} = state) do
    {lhs, vars} = postwalk(lhs)
    {match, state} = State.gensym(state)
    match_node = ~S"""
    'Elixir.Etude.Match':compile(unquote(lhs), nil)
    """
    |> erl(-1)
    |> compile_match()

    {match_var, state} = State.put_match(state, match_node)

    location = {state.module, f, a, [line: line, file: "TODO"]} |> escape(-1)

    assign = ~S"""
    unquote(match) = 'Elixir.Etude.Future':cache(
      'Elixir.Etude.Future':location(
        (unquote(match_var))(unquote(rhs), #{}),
        unquote(location)
      )
    )
    """
    |> erl(line)

    {assigns, state} = Enum.map_reduce(vars, state, fn({name, {{_, line, n} = var, _}}, state) ->
      state = State.put_var(state, n)
      {tmp, state} = State.gensym(state)
      ast = ~S"""
      unquote(var) = 'Elixir.Etude.Future':map(unquote(match), fun(unquote(tmp)) ->
        maps:get(unquote(name), unquote(tmp))
      end)
      """
      |> erl(line)
      {ast, state}
    end)

    node = {:block, line, [assign | assigns]}

    {node, state}
  end

  defp postwalk(lhs) do
    Prelude.ErlSyntax.postwalk(lhs, %{}, fn
      ({:var, _, :_} = var, acc) ->
        binding = make_binding(var)
        {binding, acc}
      ({:var, line, name} = var, acc) ->
        name = escape(name, line)
        binding = make_binding(var)
        {binding, Map.put(acc, name, {var, binding})}
      (node, acc) ->
        {node, acc}
    end)
  end

  defp elixir_scoping?({:tuple, _, items}) do
    Enum.all?(items, fn(node) ->
      elem(node, 0) == :var
    end)
  end
  defp elixir_scoping?(_) do
    false
  end
end
