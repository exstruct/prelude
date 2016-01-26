defmodule Prelude.Etude.Cons do
  use Prelude.Etude.Node

  def exit({:cons, line, value, tail}, state) do
    {{:cons, line, value, tail}, state}
  end
end
