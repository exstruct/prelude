defmodule Prelude.Etude.Integer do
  use Prelude.Etude.Node

  def exit({:integer, line, value}, state) do
    {{:integer, line, value}, state}
  end
end
