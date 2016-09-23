defmodule Prelude.Etude.Node do
  import Prelude.ErlSyntax
  alias Prelude.Etude.State

  defmacro __using__(_) do
    quote do
      import Prelude.ErlSyntax
      alias Prelude.Etude.State
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

  def acc_pending(value, state, pending) do
    if ready?(value, state) do
      {value, pending}
    else
      value = unwrap(value)
      var = var_for_node(value)
      {var, [{var, value} | pending]}
    end
  end

  def extract_pending(pending) do
    {values, vars, _} = Enum.reduce(pending, {[], [], %{}}, fn
      ({var, value}, {values, vars, cache}) ->
        var_key = put_elem(var, 1, -1)
        if Map.get(cache, var_key) do
          {values, vars, cache}
        else
          {[value | values], [var | vars], Map.put(cache, var_key, true)}
        end
    end)
    {values, vars}
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
    {:cons, -1, unwrap(argument), cons(arguments)}
  end

  def wrap({:__ETUDE_THUNK__, _, _} = node) do
    node
  end
  def wrap(node) do
    {:__ETUDE_THUNK__, -1, node}
  end

  def unwrap({:__ETUDE_THUNK__, _, node}) do
    node
  end
  def unwrap(list) when is_list(list) do
    Enum.map(list, &unwrap/1)
  end
  def unwrap(node) do
    node
  end

  def ready?(node, _state) when is_tuple(node) and elem(node, 0) in [:block, :call, :case, :cond, :if, :op, :var] do
    false
  end
  def ready?(value, _state) when is_atom(value) do
    true
  end
  def ready?(_node, _state) do
    true
  end

  ## TODO normalize line numbers so we can have consistent names
  def var_for_node(node) do
    line = elem(node, 1)
    node = put_elem(node, 1, -1)
    {:var, line, :"_etude_#{:erlang.phash2(node)}"}
  end

  def etude_dispatch do
    {:var, -1, :__etude_dispatch__}
  end







  def wrap_value(value, state, deps, vars) do
    if ready?(value, state) do
      {value, state, deps, vars}
    else
      {var, state} = State.gensym(state)
      {var, state, [to_term(value) | deps], [var | vars]}
    end
  end

  def wrap_node(node, state, [], _) do
    {node, state}
  end
  def wrap_node(node, state, [dep], [var]) do
    node = ~S"""
    'Elixir.Etude.Future':map(
      unquote(dep),
      fun(unquote(var)) ->
        unquote(node)
      end
    )
    """
    |> erl(elem(node, 1))
    {node, state}
  end
  def wrap_node(node, state, deps, vars) do
    deps = cons(deps)
    vars = cons(vars)
    node = ~S"""
    'Elixir.Etude.Future':map(
      'Elixir.Etude.Future':parallel(unquote(deps)),
      fun(unquote(vars)) ->
        unquote(node)
      end
    )
    """
    |> erl(elem(node, 1))
    {node, state}
  end

  defp to_term(future) do
    ~S"""
    'Elixir.Etude.Future':to_term(unquote(future))
    """
    |> erl(-1)
  end

  def make_binding({:var, line, name}) do
    name = escape(name, line)
    binding = erl(~S"""
    #{'__struct__' => 'Elixir.Etude.Match.Binding',
    name => unquote(name)}
    """, line)
  end

  def compile_match(node) do
    {:value, expr, _} = :erl_eval.expr(node, [])
    escape(expr)
  catch
    _, error ->
      IO.inspect node
      IO.inspect error
      throw error
  end
end
