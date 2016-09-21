defmodule Prelude.Etude.Node.Op do
  use Prelude.Etude.Node

  def exit({:op, line, name, lhs, rhs}, state) do
    {lhs, state, deps, vars} = wrap_value(lhs, state, [], [])
    {rhs, state, deps, vars} = wrap_value(rhs, state, deps, vars)
    {:op, line, name, lhs, rhs}
    |> wrap_node(state, deps, vars)
  end
end
