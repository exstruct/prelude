defmodule Prelude.Etude.String do
  import Prelude.Etude.Utils

  def exit({:string, line, _} = node) do
    ready(node, line)
  end
end
