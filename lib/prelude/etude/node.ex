defmodule Prelude.Etude.Node do
  defmacro __using__(_) do
    quote do
      import Prelude.ErlSyntax
      import unquote(__MODULE__)
    end
  end

  def traverse_fn(name) do
    fn(node, acc) ->
      mod = impl_for(node)
      cond do
        function_exported?(mod, name, 2) ->
          apply(mod, name, [node, acc])
        function_exported?(mod, name, 1) ->
          node = apply(mod, name, [node])
          {node, acc}
        true ->
          {node, acc}
      end
    end
  end

  def impl_for(node) do
    mod = Module.concat(Prelude.Etude, camelize(node))
    mod.module_info()
    mod
  catch
    _, _ ->
      nil
  end

  defp camelize(node) do
    node
    |> elem(0)
    |> :erlang.atom_to_binary(:utf8)
    |> Mix.Utils.camelize()
  end
end
