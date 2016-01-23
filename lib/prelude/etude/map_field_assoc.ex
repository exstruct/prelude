defmodule Prelude.Etude.MapFieldAssoc do
  import Prelude.Etude.Utils

  def exit({:map_field_assoc, line, ready(key), ready(value)}) do
    ready({:map_field_assoc, line, key, value}, line)
  end
  def exit(node) do
    node
  end
end
