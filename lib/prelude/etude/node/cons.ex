defmodule Prelude.Etude.Node.Cons do
  use Prelude.Etude.Node

  def exit({:cons, line, value, tail}, state) do
    value = unwrap(value)
    tail_u = unwrap(tail)

    node = if ready?(tail, state) do
      {:cons, line, value, tail_u}
    else
      erl(~S"""
      #{'__struct__' => 'Elixir.Prelude.Etude.Node.Cons.Thunk',
        value => unquote(value),
        tail => unquote(tail_u)}
      """, line)
      |> wrap()
    end

    {node, state}
  end
end

defmodule Prelude.Etude.Node.Cons.Thunk do
  defstruct value: nil,
            tail: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Cons.Thunk do
  def resolve(%{value: value, tail: tail}, state) do
    Etude.Thunk.resolve(tail, state, fn(tail, state) ->
      {[value | tail], state}
    end)
  end
end
