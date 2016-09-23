defmodule Prelude.Etude do
  alias Prelude.ErlSyntax
  require Prelude.ErlSyntax

  @blacklisted_functions [__struct__: 0, __info__: 1, __etude__: 3, __after_compile__: 2]

  defmacro __using__(_) do
    quote do
      @before_compile Prelude.Etude
    end
  end

  defmacro __before_compile__(env) do
    module = rename_module(env.module)
    quote line: -1 do
      def __etude__(name, arity, dispatch) do
        unquote(module).__etude__(name, arity, dispatch)
      end
    end
  end

  def compile(forms, _opts) do
    {module, attributes, exports, functions} = Enum.reduce(forms, {nil, [], %{}, %{}}, &partition/2)

    #if Mix.env == :test do
    #  :parse_trans_pp.pp_src(forms, '.test/#{module}.in.erl')
    #end

    initial_state = %Prelude.Etude.State{
      locals: Enum.reduce(functions, %{}, fn({key, _}, acc) -> Map.put(acc, key, true) end),
      exports: exports,
      module: module
    }

    functions
    |> Enum.reduce({[], []}, &handle_function(&1, initial_state, &2))
    |> concat(attributes, module)
  end

  defp partition({:function, _, name, arity, clauses}, {module, attributes, exports, funs}) do
    key = {name, arity}
    prev = Map.get(funs, key, [])
    {module, attributes, exports, Map.put(funs, key, prev ++ clauses)}
  end
  defp partition({:attribute, _, :export, exported}, {module, attributes, exports, funs}) do
    exports = Enum.reduce(exported, exports, fn
      ({name, 0}, acc) when name in @blacklisted_functions ->
        acc
      ({name, arity}, acc) ->
        Map.put(acc, {name, arity}, true)
    end)
    {module, attributes, exports, funs}
  end
  defp partition({:attribute, _, :spec, _}, state) do
    state
  end
  defp partition({:attribute, line, :module, module}, {_, attributes, exports, funs}) do
    module = rename_module(module)
    attr = {:attribute, line, :module, module}
    {module, [attr | attributes], exports, funs}
  end
  defp partition({:attribute, _, :file, _}, acc) do
    acc
  end
  defp partition(other, {module, attributes, exports, funs}) do
    {module, [other | attributes], exports, funs}
  end

  defp handle_function({{name, arity}, _}, _state, {public_etudes, private_etudes}) when {name, arity} in @blacklisted_functions do
    {public_etudes,
     private_etudes}
  end
  defp handle_function({{name, arity}, clauses}, state, {public_etudes, private_etudes}) do
    state = %{state | function: {name, arity},
                       public?: Map.has_key?(state.exports, {name, arity})}

    enter = Prelude.Etude.Node.traverse_fn(:enter)
    exit = Prelude.Etude.Node.traverse_fn(:exit)
    node = {:function, -1, name, arity, clauses}

    {additional_public, additional_private} = Prelude.ErlSyntax.traverse(node, state, enter, exit)

    {public_etudes ++ additional_public,
     private_etudes ++ additional_private}
  end

  defp concat({[], private_etudes}, attributes, module) do
    Enum.reverse(attributes)
    ++ handle_etudes(:__etude_local__, private_etudes, module)
  end
  defp concat({public_etudes, private_etudes}, attributes, module) do
    export_etudes(attributes)
    ++ handle_etudes(:__etude__, public_etudes, module)
    ++ handle_etudes(:__etude_local__, private_etudes, module)
  end

  defp export_etudes(attributes) do
    [{:attribute, -1, :export, [__etude__: 3]} | attributes]
    |> Enum.reverse()
  end

  defp handle_etudes(_, [], _) do
    []
  end
  defp handle_etudes(:__etude__ = name, etudes, module) do
    [{:function, -1, name, 3, Enum.reverse([etude_default_clause(module) | etudes])}]
  end
  defp handle_etudes(:__etude_local__ = name, etudes, _) do
    [{:function, -1, name, 3, Enum.reverse(etudes)}]
  end

  defp etude_default_clause(module) do
    module = ErlSyntax.escape(module)
    body = ~S"""
    erlang:error('Elixir.UndefinedFunctionError':exception([{arity, Arity}, {function, Function}, {module, unquote(module)}]))
    """
    |> ErlSyntax.erl()
    {:clause, -1, [{:var, -1, :Function}, {:var, -1, :Arity}, {:var, -1, :_}], [], [body]}
  end

  defp rename_module(module) do
    parts = Module.split(module)
    Enum.join(["Etude" | parts], ".") |> String.to_atom()
  end
end
