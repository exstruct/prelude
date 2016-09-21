defmodule Prelude.Etude.Node.Bin do
  use Prelude.Etude.Node

  def exit({:bin, line, children}, state) do
    {children, {deps, vars, state}} = split_ready_children(children, state)
    wrap_node({:bin, line, children}, state, deps, vars)
  end

  defp split_ready_children(children, state) do
    Enum.map_reduce(children, {[], [], state}, fn
      ({op, line, value, size, opts}, {deps, vars, state}) ->
        {value, state, deps, vars} = wrap_value(value, state, deps, vars)
        {size, state, deps, vars} = wrap_value(size, state, deps, vars)
        {{op, line, value, size, opts}, {deps, vars, state}}
    end)
  end
end
