defmodule Prelude.Etude.Node.Cons do
  use Prelude.Etude.Node

  def exit({:cons, line, head, tail_w}, state) do
    head = unwrap(head)
    tail = unwrap(tail_w)

    node = if ready?(tail_w, state) do
      {:cons, line, head, tail}
    else
      ~S"""
      #{'__struct__' => 'Elixir.Prelude.Etude.Node.Cons.Thunk',
        head => unquote(head),
        tail => unquote(tail)}
      """
      |> erl(line)
      |> wrap()
    end

    {node, state}
  end
end

defmodule Prelude.Etude.Node.Cons.Thunk do
  defstruct head: nil,
            tail: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Cons.Thunk do
  def resolve(%{head: head, tail: tail}, state) when is_list(tail) do
    {[head | tail], state}
  end
  def resolve(%{head: head, tail: tail}, state) do
    Etude.Thunk.resolve(tail, state, fn(tail, state) ->
      {[head | tail], state}
    end)
  end
end
