defmodule Prelude.Etude.Node.Match do
  use Prelude.Etude.Node

  def exit({:match, _, {:var, _, _}, _} = node, state) do
    {node, state}
  end
  def exit({:match, line, lhs, rhs}, state) do
    {lhs, vars} = postwalk(lhs)
    body = {:map, line, Enum.map(vars, fn({name, {_, binding}}) ->
               {:map_field_assoc, line, name, binding}
             end)}
    {match, state} = State.gensym(state)

    assign = ~S"""
    unquote(match) = 'Elixir.Etude.Future':cache(
      ('Elixir.Etude.Match':compile(unquote(lhs), nil, unquote(body)))(unquote(rhs), #{})
    )
    """
    |> erl(line)

    {assigns, state} = Enum.map_reduce(vars, state, fn({name, {{_, line, _} = var, _}}, state) ->
      {tmp, state} = State.gensym(state)
      ast = ~S"""
      unquote(var) = 'Elixir.Etude.Future':map(unquote(match), fun(unquote(tmp)) -> maps:get(unquote(name), unquote(tmp)) end)
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
end
