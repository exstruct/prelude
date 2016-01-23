defmodule Prelude.Etude.Nil do
  import Prelude.Etude.Utils

  def exit({:nil, line} = node) do
    ready(node, line)
  end
end
