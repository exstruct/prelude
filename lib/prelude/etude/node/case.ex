defmodule Prelude.Etude.Node.Case do
  use Prelude.Etude.Node

  def exit({:case, line, value, clauses}, state) do
    {clauses, state} = Prelude.Etude.Node.Clause.combine_clauses(clauses, line, state)
    [{:clause, _, [val_var], _, [match]}] = clauses

    node = ~S"""
    begin
      unquote(val_var) = unquote(value),
      unquote(match)
    end
    """
    |> erl(line)

    {node, state}
  end
end
