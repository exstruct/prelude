defmodule Prelude.Etude.Node.Map do
  use Prelude.Etude.Node

  def exit({:map, line, children}, state) do
    node = process_children(children, state)
    |> handle_pending(line)
    {node, state}
  end
  def exit({:map, line, map, children}, state) do
    node = process_children(children, state)
    |> handle_pending_update(map, ready?(map, state), line)
    {node, state}
  end

  defp process_children(children, state) do
    Enum.map_reduce(children, [], fn({type, l, key, value}, acc) ->
      {key, acc} = acc_pending(key, state, acc)
      {{type, l, key, unwrap(value)}, acc}
    end)
  end

  defp handle_pending({children, pending}, line) do
    handle_pending({children, pending}, line, {:map, line, children})
  end
  defp handle_pending({_children, []}, _line, map) do
    map
  end
  defp handle_pending({_children, pending}, line, map) do
    {values, vars} = extract_pending(pending)
    values = cons(values)
    vars = cons(vars)

    ~S"""
    #{'__struct__' => 'Elixir.Prelude.Etude.Node.Map.Thunk',
      arguments => unquote(values),
      construct => fun(unquote(vars)) ->
        unquote(map)
      end}
    """
    |> erl(line)
    |> wrap()
  end

  defp handle_pending_update(acc, map, true, line) do
    handle_pending(acc, line, unwrap(map))
  end
  defp handle_pending_update({children, pending}, map, _, line) do
    {values, vars} = extract_pending(pending)
    values = cons(values)
    vars = cons(vars)
    map = unwrap(map)
    map_var = var_for_node(map)
    update = {:map, line, map_var, children}

    ~S"""
    #{'__struct__' => 'Elixir.Prelude.Etude.Node.MapUpdate.Thunk',
      map => unquote(map),
      arguments => unquote(values),
      construct => fun(unquote(map_var), unquote(vars)) ->
        unquote(update)
      end}
    """
    |> erl(line)
    |> wrap()
  end
end

defmodule Prelude.Etude.Node.Map.Thunk do
  defstruct arguments: [],
            construct: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Map.Thunk do
  def resolve(%{construct: construct, arguments: arguments}, state) do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      {construct.(arguments), state}
    end)
  end
end

defmodule Prelude.Etude.Node.MapUpdate.Thunk do
  defstruct map: %{},
            arguments: [],
            construct: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.MapUpdate.Thunk do
  def resolve(%{map: map, construct: construct, arguments: arguments}, state) do
    Etude.Thunk.resolve_all([map | arguments], state, fn([map | arguments], state) ->
      {construct.(map, arguments), state}
    end)
  end
end
