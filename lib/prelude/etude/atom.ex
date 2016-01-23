defmodule Prelude.Etude.Atom do
  import Prelude.Etude.Utils

  def exit({:atom, line, _} = node) do
    ready(node, line)
  end
end
