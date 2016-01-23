defmodule Prelude.Etude.Map do
  import Prelude.Etude.Utils, except: [extract_pending: 1]

  def exit({:map, line, children}) do
    case extract_pending(children) do
      {children, []} ->
        ready({:map, line, children}, line)
      {children, pending_ops} ->
        compile_pending(pending_ops, line, {:map, line, children})
    end
  end
  def exit({:map, line, map, children}) do
    case extract_pending([map | children]) do
      {[map | children], []} ->
        ready({:map, line, map, children}, line)
      {[map | children], pending_ops} ->
        compile_pending(pending_ops, line, {:map, line, map, children})
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
  defp extract_pending([{type, line, ready(key), value} | rest], children_acc, pending_acc) when type in [:map_field_assoc, :map_field_exact] do
    children_acc = [{type, line, key, var_for_node(value)} | children_acc]
    pending_acc = [value | pending_acc]
    extract_pending(rest, children_acc, pending_acc)
  end
  defp extract_pending([{type, line, key, ready(value)} | rest], children_acc, pending_acc) when type in [:map_field_assoc, :map_field_exact] do
    children_acc = [{type, line, var_for_node(key), value} | children_acc]
    pending_acc = [key | pending_acc]
    extract_pending(rest, children_acc, pending_acc)
  end
  defp extract_pending([{type, line, key, value} | rest], children_acc, pending_acc) when type in [:map_field_assoc, :map_field_exact] do
    children_acc = [{type, line, var_for_node(key), var_for_node(value)} | children_acc]
    pending_acc = [value, key | pending_acc]
    extract_pending(rest, children_acc, pending_acc)
  end
  defp extract_pending([node | rest], children_acc, pending_acc) do
    children_acc = [var_for_node(node) | children_acc]
    pending_acc = [node | pending_acc]
    extract_pending(rest, children_acc, pending_acc)
  end
end
