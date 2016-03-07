defmodule Prelude.Etude.Node.Op do
  use Prelude.Etude.Node

  def exit({:op, line, name, lhs_w, rhs_w}, state) do
    lhs = unwrap(lhs_w)
    rhs = unwrap(rhs_w)

    node = if ready?(lhs_w, state) && ready?(rhs_w, state) do
      {:op, line, name, lhs, rhs}
    else
      op = escape(name, line)
      arguments = cons([lhs, rhs])

      ~S"""
      #{'__struct__' => 'Elixir.Prelude.Etude.Node.Op.Thunk',
        arguments => unquote(arguments),
        op => unquote(op)}
      """
      |> erl(line)
      |> wrap()
    end

    {node, state}
  end
end

defmodule Prelude.Etude.Node.Op.Thunk do
  defstruct arguments: [],
            op: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Op.Thunk do
  def resolve(%{op: op, arguments: arguments}, state) do
    Etude.Thunk.resolve_all(arguments, state, fn([a, b], state) ->
      {apply(:erlang, op, [a, b]), state}
    end)
  end
end
