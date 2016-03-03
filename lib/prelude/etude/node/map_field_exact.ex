defmodule Prelude.Etude.Node.MapFieldExact do
  use Prelude.Etude.Node

  def exit({:map_field_exact, line, key, value}, state) do
    {{:map_field_exact, line, key, value}, state}
  end
end
