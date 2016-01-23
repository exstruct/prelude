defmodule Prelude.Etude.Tuple do
  import Prelude.Etude.Utils

  def exit({:tuple, line, children}) do
    case extract_pending(children) do
      {children, []} ->
        ready({:tuple, line, children}, line)
      {children, pending_ops} ->
        compile_pending(pending_ops, line, {:tuple, line, children})
    end
  end
end
