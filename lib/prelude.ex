defmodule Prelude do
  @vsn Mix.Project.config[:version]
  @elixir_docs 'ExDc'

  def compile_string(str, opts \\ []) do
    str
    |> Code.string_to_quoted!(opts)
    |> compile_quoted(opts)
  end

  def compile_quoted(quoted, opts \\ []) do
    quoted
    |> eval_quoted(opts)
    |> decompile_beam()
    |> compile_forms([{:from_elixir, true} | opts])
  end

  def compile_forms(forms, opts \\ [])
  def compile_forms({forms, docs}, opts) when is_binary(docs) do
    case compile_forms(forms, opts) do
      {:ok, module, beam} ->
        beam = :elixir_module.add_beam_chunk(beam, @elixir_docs, docs)
        {:ok, module, beam}
      other ->
        other
    end
  end
  def compile_forms(forms, opts) do
    Prelude.Compiler.compile_forms(forms, opts)
  end

  def parse_transform(forms, _options) do
    compile_forms(forms, [out: :forms])
  end

  defmacro defetude(name, block) do
    quote bind_quoted: [name: Macro.escape(name),
                        block: Macro.escape(block)] do
      Prelude.compile_quoted({:defmodule, [import: Kernel], [name, block]}, [file: __ENV__.file, line: __ENV__.line])
    end
  end

  defp eval_quoted(quoted, opts) do
    orig = Code.compiler_options()
    Code.compiler_options(docs: true, debug_info: true)
    res = Code.eval_quoted(quoted, [], opts)
    Code.compiler_options(orig)
    res
  end

  defp decompile_beam({{:module, _, _, _} = result, _}) do
    decompile_beam(result)
  end
  defp decompile_beam({:module, module, beam, _}) do
    case :beam_lib.chunks(beam, [:abstract_code, @elixir_docs]) do
      {:ok, {^module, [{:abstract_code, {:raw_abstract_v1, forms}}, {@elixir_docs, docs}]}} ->
        {forms, docs}
      {:ok, {:no_debug_info, _}} ->
        throw({:forms_not_found, module})
      {:error, :beam_lib, {:file_error, _, :enoent}} ->
        throw({:module_not_found, module})
    end
  end
end
