defmodule Prelude.Etude.Node do
  defmacro __using__(_) do
    quote do
      import Prelude.ErlSyntax
      alias Prelude.Etude.State
      import unquote(__MODULE__)
    end
  end

  @ready Module.concat(__MODULE__, :__PRELUDE_READY__)
  @pending Module.concat(__MODULE__, :__PRELUDE_PENDING__)

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
    mod = Module.concat(Prelude.Etude.Node, camelize(node))
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

  def put_arguments(call, arguments) when is_list(arguments) do
    put_arguments(call, cons(arguments))
  end
  def put_arguments(call, {:nil, _}) do
    call
  end
  def put_arguments(call, arguments) do
    {:map, -1,
      call,
      [{:map_field_assoc, -1, {:atom, -1, :arguments},
        arguments}]}
  end

  def cons([]) do
    {:nil, -1}
  end
  def cons([argument | arguments]) do
    {:cons, -1, argument, cons(arguments)}
  end

  defmacro ready(node \\ Macro.var(:_, nil)) do
    quote do
      {unquote(@ready), unquote(node)}
    end
  end

  defmacro pending(node \\ Macro.var(:_, nil)) do
    quote do
      {unquote(@pending), unquote(node)}
    end
  end

  def extract_pending(list, _state) do
    ## lookup ready variables in the scope in state
    {children, pending} = Enum.map_reduce(list, [], fn
      (pending(value), acc) ->
        {var_for_node(value), [value | acc]}
      (ready(value), acc) ->
        {value, acc}
      (value, acc) ->
        {value, acc}
    end)
    {children, pending |> Enum.uniq() |> Enum.reverse()}
  end

  def var_for_node(node) do
    line = elem(node, 1)
    {:var, line, :"_etude_#{:erlang.phash2(node)}"}
  end
end
