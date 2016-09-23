defmodule Prelude.Etude.Node.Block do
  use Prelude.Etude.Node

  def enter(node, state) do
    state = State.scope_enter(state)
    {node, state}
  end

  def exit({:block, _, [node]}, state) do
    state = State.scope_exit(state)
    {node, state}
  end
  def exit({:block, _line, _exprs} = node, state) do
    # TODO handle the side-effect calls
    state = State.scope_exit(state)
    {node, state}
  end
end
