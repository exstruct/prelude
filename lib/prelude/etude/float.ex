defmodule Prelude.Etude.Float do
  import Prelude.Etude.Utils

  def exit({:float, line, _} = node) do
    ready(node, line)
  end
end
