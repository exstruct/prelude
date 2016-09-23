defmodule Prelude.Etude.Node.NamedFun do
  use Prelude.Etude.Node

  def enter({:named_fun, _, name, _} = node, state) do
    state = State.put_var(state, name)
    {node, state}
  end

  def exit({:named_fun, line, name, {:clauses, clauses}}, state) do
    {clauses, state} = Prelude.Etude.Node.Clause.combine_clauses(clauses, line, state)
    node = {:named_fun, line, name, {:clauses, clauses}}
    {node, state}
  end
end
