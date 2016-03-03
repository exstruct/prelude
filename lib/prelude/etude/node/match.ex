defmodule Prelude.Etude.Node.Match do
  use Prelude.Etude.Node

  def exit({:match, line, lhs, rhs}, state) do
    {{:match, line, lhs, rhs}, state}
  end
end
