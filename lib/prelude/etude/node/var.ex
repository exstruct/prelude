defmodule Prelude.Etude.Node.Var do
  use Prelude.Etude.Node

  def exit({:var, line, name} = node, state) do
    if Prelude.Etude.State.static_var?(state, node) do
      {{:var, line, name}, state}
    else
      {wrap({:var, line, name}), state}
    end
  end
end
