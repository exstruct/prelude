defmodule Prelude.Compiler do
  def compile_forms(forms, opts) do
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
    opts = if opts[:from_elixir] do
      [:binary | opts]
    else
      [:binary,
       :report_errors,
       :report_warnings | opts]
    end

    case :compile.forms(forms, opts) do
      {:ok, module, beam, _} ->
        {:ok, module, beam}
      other ->
        other
    end
  end
end
