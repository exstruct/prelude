defmodule Prelude.Etude.Node.Map do
  use Prelude.Etude.Node

  def exit({:map, line, children}, state) do
    {children, {deps, vars, state}} = split_ready_children(children, state)
    wrap_node({:map, line, children}, state, deps, vars)
  end
  def exit({:map, line, map, children}, state) do
    {children, {deps, vars, state}} = split_ready_children(children, state)
    {map, state, deps, vars} = wrap_value(map, state, deps, vars)
    wrap_node({:map, line, map, children}, state, deps, vars)
  end

  defp split_ready_children(children, state) do
    Enum.map_reduce(children, {[], [], state}, fn
      ({op, line, key, value}, {deps, vars, state}) ->
        {key, state, deps, vars} = wrap_value(key, state, deps, vars)
        {{op, line, key, value}, {deps, vars, state}}
    end)
  end
end
