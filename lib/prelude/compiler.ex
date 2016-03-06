defmodule Prelude.Compiler do
  def compile_elixir(module, block, vars, env) do
    :prelude_elixir_module.compile(module, block, vars, env)
  end

  def compile_erlang(forms, opts) do
    ## TODO pull backend from module attribute
    backend = Prelude.Etude
    forms
    |> backend.compile(opts)
    |> pp()
    |> compile(opts)
  end

  defp pp(forms) do
    :parse_trans_pp.pp_src(forms, '.test/#{module_name(forms)}.erl.out')
    forms
  end

  defp module_name([{:attribute, _, :module, name} | _]) do
    name
  end
  defp module_name([_ | rest]) do
    module_name(rest)
  end

  defp compile(forms, opts) do
    case opts[:out] do
      :forms ->
        forms
      _ ->
        to_beam(forms, opts)
    end
  end

  defp to_beam(forms, opts) do
    opts = [
      :binary,
      :report_errors,
      :report_warnings
    ] ++ opts

    :compile.forms(forms, opts)
  end

  def eval_forms(erl, env, scope) do
    parsed_binding = case :elixir_scope.load_binding([], scope) do
      {binding, _, _} ->
        binding
      {binding, _} ->
        binding
    end
    {:value, value, _} = erl_eval(erl, parsed_binding, env)
    value
  end

  defp erl_eval(erl, parsed_binding, _) do
    :erl_eval.expr(erl, parsed_binding, :none, :none, :none)
  end
end
