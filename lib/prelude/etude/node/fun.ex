defmodule Prelude.Etude.Node.Fun do
  use Prelude.Etude.Node

  def exit({:fun, line, {:clauses, clauses}}, state) do
    {clauses, state} = Prelude.Etude.Node.Clause.combine_clauses(clauses, line, state)
    node = {:fun, line, {:clauses, clauses}}
    {node, state}
  end
end
