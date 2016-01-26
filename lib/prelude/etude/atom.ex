defmodule Prelude.Etude.Atom do
  use Prelude.Etude.Node

  def exit({:atom, line, value}, state) do
    {{:atom, line, value}, state}
  end
end
