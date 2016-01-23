defmodule Prelude.Etude.Utils do
  import Prelude.ErlSyntax

  defmacro ready(var, line \\ Macro.var(:_, nil)) do
    quote do
      {:tuple, unquote(line), [{:atom, unquote(line), :__ETUDE_READY__}, unquote(var)]}
    end
  end

  def pending do
    {:atom, -1, :__ETUDE_PENDING__}
  end

  def extract_vars(node) do
    postwalk(node, [], fn
      ({:var, _, name} = var, acc) when name != :_ ->
        {var, [var | acc]}
      (other, acc) ->
        {other, acc}
    end)
    |> elem(1)
    |> Enum.uniq()
    |> Enum.reverse()
  end

  def in_scope?(var, scopes) when is_list(scopes) do
    Enum.any?(scopes, &in_scope?(var, &1))
  end
  def in_scope?({:var, _, target}, {:var, _, name}) do
    target == name
  end

  def extract_pending(children) do
    {children, pending} = Enum.map_reduce(children, [], fn
      (ready(value), i) ->
        {value, i}
      (value, acc) ->
        {var_for_node(value), [value | acc]}
    end)
    {children, pending |> Enum.uniq() |> Enum.reverse()}
  end

  def compile_pending([pending_op], line, response) do
    compile_pending_body(pending_op,
                         ready_vars_for_nodes([pending_op]) |> hd(),
                         ready(response, line),
                         pending)
  end
  def compile_pending(pending_ops, line, response) do
    compile_pending_body({:tuple, line, pending_ops},
                         {:tuple, line, ready_vars_for_nodes(pending_ops)},
                         ready(response, line),
                         {:var, line, :_})
  end
  defp compile_pending_body(pending_ops, pending_vars, response, default_match) do
    ~e"""
    case unquote(pending_ops) of
      unquote(pending_vars) ->
        unquote(response);
      unquote(default_match) ->
        unquote(pending)
    end
    """
  end

  def var_for_node(node) do
    line = elem(node, 1)
    {:var, line, :"_etude_#{:erlang.phash2(node)}"}
  end

  def vars_for_nodes(nodes) do
    nodes
    |> Enum.map(&var_for_node/1)
  end

  def ready_vars_for_nodes(nodes) do
    nodes
    |> Enum.map(fn(node) ->
      line = elem(node, 1)
      var = var_for_node(node)
      ready(var, line)
    end)
  end
end
