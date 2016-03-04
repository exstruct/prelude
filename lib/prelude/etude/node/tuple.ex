defmodule Prelude.Etude.Node.Tuple do
  use Prelude.Etude.Node

  def exit({:tuple, line, children}, state) do
    children = unwrap(children)
    {{:tuple, line, children}, state}
  end
end
