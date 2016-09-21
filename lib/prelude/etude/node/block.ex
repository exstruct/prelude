defmodule Prelude.Etude.Node.Block do
  use Prelude.Etude.Node

  def exit({:block, _, [node]}, state) do
    {node, state}
  end
  def exit({:block, line, exprs} = node, state) do
    {node, state}
  end
end
