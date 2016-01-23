defmodule Prelude.Etude.Integer do
  import Prelude.Etude.Utils

  def exit({:integer, line, _} = node) do
    ready(node, line)
  end
end
