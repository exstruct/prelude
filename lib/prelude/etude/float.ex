defmodule Prelude.Etude.Float do
  use Prelude.Etude.Node

  def exit({:float, line, value}, state) do
    {{:float, line, value}, state}
  end
end
