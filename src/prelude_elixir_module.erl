-module(prelude_elixir_module).

-export([compile/4]).

-define(acc_attr, {elixir, acc_attributes}).
-define(lexical_attr, {elixir, lexical_tracker}).
-define(persisted_attr, {elixir, persisted_attributes}).
-define(overridable_attr, {elixir, overridable}).
-define(location_attr, {elixir, location}).
-define(m(M, K), maps:get(K, M)).

compile(Module, Block, Vars, #{line := Line} = Env) when is_atom(Module) ->
  %% In case we are generating a module from inside a function,
  %% we get rid of the lexical tracker information as, at this
  %% point, the lexical tracker process is long gone.
  LexEnv = case ?m(Env, function) of
    nil -> Env#{module := Module, local := nil};
    _   -> Env#{lexical_tracker := nil, function := nil, module := Module, local := nil}
  end,

  case ?m(LexEnv, lexical_tracker) of
    nil ->
      elixir_lexical:run(?m(LexEnv, file), nil, fun(Pid) ->
        do_compile(Line, Module, Block, Vars, LexEnv#{lexical_tracker := Pid})
      end);
    _ ->
      do_compile(Line, Module, Block, Vars, LexEnv)
  end;

compile(Module, _Block, _Vars, #{line := Line, file := File}) ->
  elixir_errors:form_error([{line, Line}], File, ?MODULE, {invalid_module, Module}).

do_compile(Line, Module, Block, Vars, E) ->
  File = ?m(E, file),
  % check_module_availability(Line, File, Module),

  Docs = elixir_compiler:get_opt(docs),
  {Data, Defs, Clas, Ref} = build(Line, File, Module, Docs, ?m(E, lexical_tracker)),

  try
    {_, NE} = eval_form(Line, Module, Data, Block, Vars, E),
    {Def, Defp, Defmacro, Defmacrop, Exports, Functions} =
      elixir_def:unwrap_definitions(File, Module),

    Location = {elixir_utils:characters_to_list(elixir_utils:relative_to_cwd(File)), Line},

    [{attribute, Line, file, Location},
     {attribute, Line, module, Module},
     {attribute, Line, export, Exports} | Functions]
  after
    elixir_locals:cleanup(Module),
    ets:delete(Data),
    ets:delete(Defs),
    ets:delete(Clas),
    elixir_code_server:call({undefmodule, Ref})
  end.

build(Line, File, Module, Docs, Lexical) ->
  case ets:lookup(elixir_modules, Module) of
    [{Module, _, _, _, OldLine, OldFile}] ->
      Error = {module_in_definition, Module, OldFile, OldLine},
      elixir_errors:form_error([{line, Line}], File, ?MODULE, Error);
    _ ->
      []
  end,

  Data = ets:new(Module, [set, public]),
  Defs = ets:new(Module, [set, public]),
  Clas = ets:new(Module, [bag, public]),

  Ref = elixir_code_server:call({defmodule, self(),
                                 {Module, Data, Defs, Clas, Line, File}}),

  ets:insert(Data, {before_compile, []}),
  ets:insert(Data, {after_compile, []}),
  ets:insert(Data, {moduledoc, nil}),

  case Docs of
    true -> ets:insert(Data, {on_definition, [{'Elixir.Module', compile_doc}]});
    _    -> ets:insert(Data, {on_definition, []})
  end,

  Attributes = [behaviour, on_load, compile, external_resource],
  ets:insert(Data, {?acc_attr, [before_compile, after_compile, on_definition, derive,
                                spec, type, typep, opaque, callback|Attributes]}),
  ets:insert(Data, {?persisted_attr, [vsn|Attributes]}),
  ets:insert(Data, {?lexical_attr, Lexical}),

  %% Setup definition related modules
  elixir_def:setup(Module),
  elixir_locals:setup(Module),
  elixir_def_overridable:setup(Module),

  {Data, Defs, Clas, Ref}.

eval_form(Line, Module, _, Block, Vars, E) ->
  {Value, EE} = elixir_compiler:eval_forms(Block, Vars, E),
  elixir_def_overridable:store_pending(Module),
  EV = elixir_env:linify({Line, EE#{vars := [], export_vars := nil}}),
  % EC = eval_callbacks(Line, Data, before_compile, [EV], EV),
  elixir_def_overridable:store_pending(Module),
  {Value, EV}.
