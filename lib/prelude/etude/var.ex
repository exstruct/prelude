defmodule Prelude.Etude.Var do
  use Prelude.Etude.Node

  def exit({:var, line, name}, state) do
    {{:var, line, name}, state}
  end
end
