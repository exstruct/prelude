defmodule Prelude.Etude.Op do
  use Prelude.Etude.Node

  def exit({:op, line, name, lhs, rhs}, state) do
    {{:op, line, name, lhs, rhs}, state}
  end
end
