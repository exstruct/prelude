defmodule Prelude.Etude.Node.Call do
  use Prelude.Etude.Node

  def exit({:call, line, {:remote, _, module, function}, args}, state) do
    {_, acc} = acc_pending(module, state, [])
    {_, acc} = acc_pending(function, state, acc)
    module = unwrap(module)
    function = unwrap(function)
    args = unwrap(args)

    node = case acc do
      [] ->
        {fun, state} = State.put_call(state, elem(module, 2), elem(function, 2), args)
        wrap(put_arguments(fun, args))
      _ ->
        arguments = cons(args)

        ~S"""
        #{'__struct__' => 'Elixir.Prelude.Etude.Node.Call.Thunk',
          dispatch => unquote(etude_dispatch),
          arguments => unquote(arguments),
          module => unquote(module),
          function => unquote(function)}
        """
        |> erl(line)
        |> wrap()
    end

    {node, state}
  end
  def exit({:call, _line, fun, args}, state) do
    ## TODO
    node = case fun do
      {:atom, _, fun} ->
        {fun, state} = State.put_local_call(state, fun, args)
        wrap(put_arguments(fun, args))
    end

    {node, state}
  end
end

defmodule Prelude.Etude.Node.Call.Thunk do
  defstruct arguments: [],
            module: nil,
            function: nil,
            dispatch: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Call.Thunk do
  def resolve(%{module: module, function: function, arguments: arguments, dispatch: dispatch}, state) when is_atom(module) and is_atom(function) do
    mfa = dispatch.resolve(module, function, length(arguments))
    {%{mfa | arguments: arguments}, state}
  end
  def resolve(%{module: module, function: function, arguments: arguments, dispatch: dispatch}, state) when is_atom(module) do
    Etude.Thunk.resolve(function, state, fn(function, state) ->
      mfa = dispatch.resolve(module, function, length(arguments))
      {%{mfa | arguments: arguments}, state}
    end)
  end
  def resolve(%{module: module, function: function, arguments: arguments, dispatch: dispatch}, state) when is_atom(function) do
    Etude.Thunk.resolve(module, state, fn(module, state) ->
      mfa = dispatch.resolve(module, function, length(arguments))
      {%{mfa | arguments: arguments}, state}
    end)
  end
  def resolve(%{module: module, function: function, arguments: arguments, dispatch: dispatch}, state) do
    Etude.Thunk.resolve_all([module, function], state, fn([module, function], state) ->
      mfa = dispatch.resolve(module, function, length(arguments))
      {%{mfa | arguments: arguments}, state}
    end)
  end
end
