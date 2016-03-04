defmodule Prelude.Etude.Node.Bin do
  use Prelude.Etude.Node

  def exit({:bin, line, children}, state) do
    {process_children(line, children, state), state}
  end

  defp process_children(line, children, state) do
    children
    |> Enum.map_reduce([], fn({:bin_element, l, value, size, opts}, acc) ->
      {value, acc} = acc_pending(value, state, acc)
      {size, acc} = acc_pending(size, state, acc)
      {{:bin_element, l, value, size, opts}, acc}
    end)
    |> handle_pending(line)
  end

  defp handle_pending({children, []}, line) do
    {:bin, line, children}
  end
  defp handle_pending({children, pending}, line) do
    {values, vars} = extract_pending(pending)
    values = cons(values)
    vars = cons(vars)
    bin = {:bin, line, children}

    erl(~S"""
    #{'__struct__' => 'Elixir.Prelude.Etude.Node.Bin.Thunk',
      arguments => unquote(values),
      construct => fun(unquote(vars)) ->
        unquote(bin)
      end}
    """, line)
    |> wrap()
  end
end

defmodule Prelude.Etude.Node.Bin.Thunk do
  defstruct arguments: [],
            construct: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Bin.Thunk do
  def resolve(%{construct: construct, arguments: arguments}, state) do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      {construct.(arguments), state}
    end)
  end
end
