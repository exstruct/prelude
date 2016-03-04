defmodule Prelude.Etude.Node.Case do
  use Prelude.Etude.Node

  def exit({:case, line, value, clauses}, state) do
    # TODO
    {{:case, line, unwrap(value), unwrap(clauses)}, state}
  end
end
