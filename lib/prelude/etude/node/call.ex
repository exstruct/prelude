defmodule Prelude.Etude.Node.Call do
  use Prelude.Etude.Node

  def exit({:call, line, {:remote, _, {:atom, _, module}, {:atom, _, function}}, args}, state) do
    {func, state} = State.put_call(state, module, function, args)
    arguments = cons(args)
    node = ~S"""
    'Elixir.Etude.Future':ap(unquote(func), unquote(arguments))
    """
    |> erl(line)
    {node, state}
  end
  def exit({:call, line, {:remote, _, module, function}, args} = node, state) do
    {node, state}
  end
  def exit({:call, line, {:atom, _, fun}, args} = node, state) do
    {func, state} = State.put_local_call(state, fun, args)
    arguments = cons(args)
    node = ~S"""
    'Elixir.Etude.Future':ap(unquote(func), unquote(arguments))
    """
    |> erl(line)
    {node, state}
  end
end
