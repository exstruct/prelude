defmodule Prelude.Etude.Node.MapFieldAssoc do
  use Prelude.Etude.Node

  def exit({:map_field_assoc, line, key, value}, state) do
    {{:map_field_assoc, line, key, value}, state}
  end
end
