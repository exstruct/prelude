defmodule Prelude.Etude.BinElement do
  import Prelude.Etude.Utils

  def exit({:bin_element, line, value, size, type}) do
    case {value, format_size(size)} do
      {ready(value), ready(size)} ->
        ready({:bin_element, line, value, size, type}, line)
      {value, size} ->
        {:bin_element, line, value, size, type}
    end
  end

  defp format_size(size) when is_integer(size) or is_atom(size) do
    ready(size, -1)
  end
  defp format_size(size) do
    size
  end
end
