defmodule Prelude.Etude.Node.Match do
  use Prelude.Etude.Node

  def exit({:match, line, lhs, rhs}, state) do
    if ready?(rhs, state) do
      {{:match, line, lhs, unwrap(rhs)}, state}
    else
      ## TODO handle when rhs isn't a simple variable
      {{:match, line, lhs, unwrap(rhs)}, state}
    end
  end
end
