defmodule Prelude.Etude.Case do
  import Prelude.Etude.Utils

  def exit({:case, line, ready(value), clauses}, acc) do
    {{:case, line, value, clauses}, acc}
  end
  def exit({:case, line, value, clauses}, acc) do
    clauses = for {:clause, cl, patterns, whens, body} <- clauses do
      {:clause, cl, Enum.map(patterns, &ready(&1, cl)), whens, body}
    end
    {{:case, line, value, [{:clause, line, [pending], [], [pending]} | clauses]}, acc}
  end
end
