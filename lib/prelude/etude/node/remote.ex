defmodule Prelude.Etude.Node.Remote do
  use Prelude.Etude.Node

  ## noop
  def exit(node, state) do
    {node, state}
  end
end
