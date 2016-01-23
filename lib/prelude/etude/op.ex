defmodule Prelude.Etude.Op do
  import Prelude.Etude.Utils

  def exit({:op, line, name, lhs, rhs}) do
    case extract_pending([lhs, rhs]) do
      {[lhs, rhs], []} ->
        ready({:op, line, name, lhs, rhs}, line)
      {[lhs, rhs], pending_ops} ->
        compile_pending(pending_ops, line, {:op, line, name, lhs, rhs})
    end
  end
end
