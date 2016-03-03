defmodule Prelude.Etude.Node.Call do
  use Prelude.Etude.Node

  def exit({:call, line, {:remote, rl, module, fun}, args}, state) do
    case {module, fun} do
      {{:atom, _, module}, {:atom, _, fun}} ->
        {fun, state} = State.put_call(state, module, fun, args)
        {put_arguments(fun, args), state}
    end
  end
  def exit({:call, line, fun, args}, state) do
    case fun do
      {:atom, _, fun} ->
        {fun, state} = State.put_local_call(state, fun, args)
        {put_arguments(fun, args), state}
    end
  end
end
