defmodule Prelude.Etude.Node.Case do
  use Prelude.Etude.Node

  def exit({:case, line, value_w, clauses}, state) do
    value = unwrap(value_w)

    node = if ready?(value_w, state) do
      {:case, line, value, clauses}
    else
      ## TODO evaluate any variables in the clauses
      match = {:fun, line, {:clauses, clauses}}

      ~S"""
      #{'__struct__' => 'Elixir.Prelude.Etude.Node.Case.Thunk',
        value => unquote(value),
        match => unquote(match)}
      """
      |> erl(line)
      |> wrap()
    end

    {node, state}
  end
end

defmodule Prelude.Etude.Node.Case.Thunk do
  defstruct value: nil,
            match: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Case.Thunk do
  def resolve(%{value: value, match: match}, state) do
    ## TODO make this not as eager... maybe it's not possible without
    ##      reimplementing the BEAM pattern matching
    case Etude.Serializer.TERM.__serialize__(value, state, []) do
      {value, state} ->
        {match.(value), state}
      {:await, value, state} ->
        {:await, %{__struct__: Etude.Thunk.Continuation,
                   function: fn([v], state) ->
                     resolve(%{value: v, match: match}, state)
                   end,
                   arguments: [value]}, state}
    end
  end
end
