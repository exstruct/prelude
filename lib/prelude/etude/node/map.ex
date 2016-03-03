defmodule Prelude.Etude.Node.Map do
  use Prelude.Etude.Node

  def exit({:map, line, children}, state) do
    {{:map, line, children}, state}
  end
  def exit({:map, line, map, children}, state) do
    {{:map, line, map, children}, state}
  end
end
