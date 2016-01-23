defmodule Prelude.Etude.Call do
  import Prelude.Etude.Utils

  ## TODO dispatch?
  ## TODO memoize

  def exit({:call, line, {:remote, rl, module, fun}, args}) do
    case extract_pending([module, fun | args]) do
      {[module, fun | args], []} ->
        {:call, line, {:remote, rl, module, fun}, args}
      {[module, fun | args], pending_ops} ->
        compile_pending(pending_ops, line, {:call, line, {:remote, rl, module, fun}, args})
    end
  end
  def exit({:call, line, fun, args}) do
    case extract_pending([fun | args]) do
      {[fun | args], []} ->
        {:call, line, fun, args}
      {[fun | args], pending_ops} ->
        compile_pending(pending_ops, line, {:call, line, fun, args})
    end
  end
end
