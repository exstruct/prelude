defmodule Prelude.Etude.Clause do
  import Prelude.Etude.Utils

  def enter({:clause, _, matches, _, _} = node, %{scopes: scopes} = acc) do
    scopes = [Enum.flat_map(matches, &extract_vars/1) | scopes]
    {node, %{acc | scopes: scopes}}
  end

  def exit(node, %{scopes: [_ | scopes]} = acc) do
    {node, %{acc | scopes: scopes}}
  end
end
