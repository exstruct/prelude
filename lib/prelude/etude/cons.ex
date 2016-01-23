defmodule Prelude.Etude.Cons do
  import Prelude.Etude.Utils

  def exit(node) do
    line = elem(node, 1)
    case construct(node, []) do
      {response, []} ->
        ready(response, line)
      {response, pending_ops} ->
        pending_ops
        |> Enum.uniq()
        |> Enum.reverse()
        |> compile_pending(line, response)
    end
  end

  defp construct({:cons, line, ready(value), tail}, acc) do
    {tail, acc} = construct(tail, acc)
    {{:cons, line, value, tail}, acc}
  end
  defp construct({:cons, line, value, tail}, acc) do
    {tail, acc} = construct(tail, [value | acc])
    {{:cons, line, var_for_node(value), tail}, acc}
  end
  defp construct(other, acc) do
    {other, acc}
  end
end
