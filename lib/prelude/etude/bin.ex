defmodule Prelude.Etude.Bin do
  use Prelude.Etude.Node

  def exit({:bin, line, children}, state) do
    {{:bin, line, children}, state}
  end
end
