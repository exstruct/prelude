defmodule Prelude.Etude.Node.Tuple do
  use Prelude.Etude.Node

  def exit({:tuple, line, children}, state) do
    {{:tuple, line, children}, state}
  end
end
