defmodule Prelude.Etude.Node.Atom do
  use Prelude.Etude.Node

  def exit({:atom, line, value}, state) do
    {{:atom, line, value}, state}
  end
end
