defmodule Prelude.Etude.Call do
  use Prelude.Etude.Node

  def exit({:call, line, {:remote, rl, module, fun}, args}, state) do
    {{:call, line, {:remote, rl, module, fun}, args}, state}
  end
  def exit({:call, line, fun, args}, state) do
    {{:call, line, fun, args}, state}
  end
end
