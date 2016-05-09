defmodule Prelude.Etude.State do
  defstruct scopes: [],
            locals: %{},
            exports: [],
            calls: %{},
            local_calls: %{},
            function: nil,
            public?: false,
            module: nil

  require Prelude.ErlSyntax
  alias Prelude.ErlSyntax

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
  def put_local_call(%{function: {function, arity}} = state, function, arity) do
    fn_alias = {:var, -1, :"_#{function}/#{arity}"}

    call = ErlSyntax.erl(~S"""
    #{'__struct__' => 'Elixir.Prelude.Etude.State.Thunk',
      arguments => [],
      function => unquote(fn_alias)}
    """, -1)

    {call, state}
  end
  def put_local_call(%{local_calls: calls} = state, function, arity) when is_integer(arity) do
    fn_alias = {:var, -1, :"#{function}/#{arity}"}
    {fn_alias, %{state | local_calls: Map.put(calls, {function, arity}, fn_alias)}}
  end

  def static_var?(_state, _var) do
    # TODO
    false
  end
end

defmodule Prelude.Etude.State.Thunk do
  defstruct arguments: [],
            function: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.State.Thunk do
  def resolve(%{function: function, arguments: arguments}, state) do
    Etude.Thunk.resolve_all(arguments, state, fn(arguments, state) ->
      {apply(function, arguments), state}
    end)
  end
end
