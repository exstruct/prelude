defmodule Prelude.Etude.Clause do
  use Prelude.Etude.Node

  def exit({:clause, line, matches, one, two}, state) do
    {{:clause, line, matches, one, two}, state}
  end
end
