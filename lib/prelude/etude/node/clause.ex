defmodule Prelude.Etude.Node.Clause do
  use Prelude.Etude.Node

  def exit({:clause, line, matches, clauses, body}, state) do
    {{:clause, line, matches, clauses, unwrap(body)}, state}
  end
end
