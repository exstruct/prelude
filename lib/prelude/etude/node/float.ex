defmodule Prelude.Etude.Node.Float do
  use Prelude.Etude.Node

  def exit({:float, line, value}, state) do
    {{:float, line, value}, state}
  end
end
