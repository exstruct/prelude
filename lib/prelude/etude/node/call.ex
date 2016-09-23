defmodule Prelude.Etude.Node.Call do
  use Prelude.Etude.Node

  def exit({:call, line, {:remote, _, {:atom, _, module}, {:atom, _, function}}, args}, %{module: m, function: {f, a}} = state) do
    {func, state} = State.put_call(state, module, function, args)
    arguments = cons(args)
    location = {m, f, a, [line: line, file: "TODO"]} |> escape(line)
    node = ~S"""
    'Elixir.Etude.Future':location(
      'Elixir.Etude.Future':ap(unquote(func), unquote(arguments)),
      unquote(location)
    )
    """
    |> erl(line)
    {node, state}
  end
  def exit({:call, line, {:remote, _, module, function}, args}, %{module: m, function: {f, a}} = state) do
    {module, state, deps, vars} = wrap_value(module, state, [], [])
    {function, state, deps, vars} = wrap_value(function, state, deps, vars)
    arity = escape(length(args))
    arguments = cons(args)
    location = {m, f, a, [line: line, file: "TODO"]} |> escape(line)
    ~S"""
    'Elixir.Etude.Future':location(
      'Elixir.Etude.Future':ap(
        erlang:apply(unquote(etude_dispatch), resolve, [
          unquote(module),
          unquote(function),
          unquote(arity)
        ]),
        unquote(arguments)
      ),
      unquote(location)
    )
    """
    |> erl(-1)
    |> wrap_node(state, deps, vars)
  end
  def exit({:call, line, {:atom, _, fun}, args}, %{module: module, function: {f, a}} = state) do
    {func, state} = State.put_local_call(state, fun, args)
    arguments = cons(args)
    location = {module, f, a, [line: line, file: "TOOD"]} |> escape(line)
    node = ~S"""
    'Elixir.Etude.Future':location(
      'Elixir.Etude.Future':ap(unquote(func), unquote(arguments)),
      unquote(location)
    )
    """
    |> erl(line)
    {node, state}
  end
  def exit({:call, _, {:fun, _, _}, _} = node, state) do
    {node, state}
  end
end
