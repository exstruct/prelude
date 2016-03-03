defmodule Prelude.Etude.Node.Bin do
  use Prelude.Etude.Node

  def exit({:bin, line, children}, state) do
    {{:bin, line, children}, state}
  end
end

defmodule Prelude.Etude.Node.Bin.Thunk do
  defstruct arguments: [],
            construct: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Bin.Thunk do
  def resolve(%{construct: construct, arguments: arguments}, state) when is_function(construct) do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      {construct.(arguments), state}
    end)
  end
end
