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
        expression => unquote(value),
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
  def resolve(%{expression: expression, match: match}, state) do
    ## TODO make this not as eager... maybe it's not possible without
    ##      reimplementing the BEAM pattern matching
    Etude.Thunk.resolve_recursive(expression, state, fn(expression, state) ->
      {match.(expression), state}
    end)
  end
end
