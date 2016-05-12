defmodule Prelude.Etude.Node.Block do
  use Prelude.Etude.Node

  def exit({:block, line, exprs}, state) do
    exprs = partition(exprs, {[], []}, state)
    {{:block, line, exprs}, state}
  end

  defp partition([expr], {ready, []}, _state) do
    :lists.reverse([unwrap(expr) | ready])
  end
  defp partition([expr | exprs], {ready, pending}, state) do
    if ready?(expr, state) do
      partition(exprs, {[expr | ready], pending}, state)
    else
      partition(exprs, {ready, [unwrap(expr) | pending]}, state)
    end
  end
end
