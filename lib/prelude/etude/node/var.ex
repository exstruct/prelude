defmodule Prelude.Etude.Node.Var do
  use Prelude.Etude.Node

  def exit({:var, _, name} = var, state) do
    state = State.put_var(state, name)
    {var, state}
  end
end
