defmodule Prelude.Etude.BinElement do
  use Prelude.Etude.Node

  def exit({:bin_element, line, value, size, type}, state) do
    {{:bin_element, line, value, size, type}, state}
  end
end
