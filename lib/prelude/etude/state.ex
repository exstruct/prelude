defmodule Prelude.Etude.State do
  defstruct scopes: [],
            locals: %{},
            exports: [],
            calls: %{},
            local_calls: %{},
            function: nil,
    public?: false,
    matches: %{},
    module: nil,
    var_count: 0

  def put_call(state, module, function, args) when is_list(args) do
    put_call(state, module, function, length(args))
  end
  def put_call(%{calls: calls} = state, module, function, arity) when is_integer(arity) do
    module_alias = module |> to_string() |> String.replace(".", "_")
    fn_alias = {:var, -1, :"_@@#{module_alias}__#{function}___#{arity}"}
    {fn_alias, %{state | calls: Map.put(calls, {module, function, arity}, fn_alias)}}
  end

  def put_local_call(state, function, args) when is_list(args) do
    put_local_call(state, function, length(args))
  end
  def put_local_call(%{function: {function, arity}} = state, function, arity) do
    fn_alias = {:var, -1, :"_@@@#{function}___#{arity}"}
    {fn_alias, state}
  end
  def put_local_call(%{local_calls: calls} = state, function, arity) when is_integer(arity) do
    fn_alias = {:var, -1, :"_@@#{function}___#{arity}"}
    {fn_alias, %{state | local_calls: Map.put(calls, {function, arity}, fn_alias)}}
  end

  def static_var?(_state, _var) do
    # TODO
    false
  end

  def scope_enter(%{scopes: scopes} = state) do
    %{state | scopes: [MapSet.new() | scopes]}
  end

  def scope_exit(%{scopes: [_ | scopes]} = state) do
    %{state | scopes: scopes}
  end

  def scope_vars(%{scopes: scopes}) do
    scopes
    |> Enum.reduce(MapSet.new(), fn(scope, acc) ->
      MapSet.union(scope, acc)
    end)
  end

  def put_var(%{scopes: [scope | scopes]} = state, var) do
    %{state | scopes: [MapSet.put(scope, var) | scopes]}
  end

  def put_match(%{matches: matches} = state, match) do
    matches = Map.put_new(matches, match, {:var, -1, :"_etude_match@#{map_size(matches)}"})
    {Map.get(matches, match), %{state | matches: matches}}
  end

  def gensym(%{var_count: count} = state) do
    {{:var, -1, :"_@etude_#{count}"}, %{state | var_count: count + 1}}
  end
end
