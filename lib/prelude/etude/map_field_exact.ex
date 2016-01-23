defmodule Prelude.Etude.MapFieldExact do
  import Prelude.Etude.Utils

  def exit({:map_field_exact, line, ready(key), ready(value)}) do
    ready({:map_field_exact, line, key, value}, line)
  end
  def exit(node) do
    node
  end
end
