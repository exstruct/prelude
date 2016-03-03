defmodule Prelude.Etude.State do
  defstruct scopes: [],
            locals: %{},
            exports: [],
            calls: %{},
            local_calls: %{},
            function: nil,
            public?: false

  def put_call(state, module, function, args) when is_list(args) do
    put_call(state, module, function, length(args))
  end
  def put_call(%{calls: calls} = state, module, function, arity) when is_integer(arity) do
    fn_alias = {:var, -1, :"#{module}.#{function}/#{arity}"}
    {fn_alias, %{state | calls: Map.put(calls, {module, function, arity}, fn_alias)}}
  end

  def put_local_call(state, function, args) when is_list(args) do
    put_local_call(state, function, length(args))
  end
  def put_local_call(%{local_calls: calls} = state, function, arity) when is_integer(arity) do
    fn_alias = {:var, -1, :"#{function}/#{arity}"}
    {fn_alias, %{state | local_calls: Map.put(calls, {function, arity}, fn_alias)}}
  end
end
