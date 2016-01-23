defmodule Prelude.Etude.Bin do
  import Prelude.Etude.Utils, except: [extract_pending: 1]

  def exit({:bin, line, children}) do
    case extract_pending(children) do
      {children, []} ->
        ready({:bin, line, children}, line)
      {children, pending_ops} ->
        compile_pending(pending_ops, line, {:bin, line, children})
    end
  end

  defp extract_pending(children, children_acc \\ [], pending_acc \\ [])
  defp extract_pending([], children_acc, pending_acc) do
    {children_acc |> Enum.uniq() |> Enum.reverse(),
      pending_acc |> Enum.uniq() |> Enum.reverse()}
  end
  defp extract_pending([ready(value) | rest], children_acc, pending_acc) do
    extract_pending(rest, [value | children_acc], pending_acc)
  end
  defp extract_pending([{:bin_element, line, value, size, type} | rest], children_acc, pending_acc) do
    {value, pending_acc} = extract_pending_value(value, pending_acc)
    {size, pending_acc} = extract_pending_value(size, pending_acc)

    children_acc = [{:bin_element, line, value, size, type} | children_acc]
    extract_pending(rest, children_acc, pending_acc)
  end

  defp extract_pending_value(ready(value), pending) do
    {value, pending}
  end
  defp extract_pending_value(value, pending) do
    {var_for_node(value), [value | pending]}
  end
end
