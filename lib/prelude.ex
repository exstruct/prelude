defmodule Prelude do
  @vsn Mix.Project.config[:version]

  defmacro __using__(opts) do
    backend = opts[:backend] || Prelude.Etude
    quote do
      use unquote(backend)
      @after_compile __MODULE__

      def __after_compile__(env, beam) do
        module = {:module, __MODULE__, beam, []}
        opts = unquote([{:from_elixir, true} | opts])
        case Prelude.compile_beam(module, opts) do
          {:ok, name, beam} ->
            ## TODO how do we know if it's being compiled to the filesystem or in memory?
            Mix.Project.compile_path()
            |> Path.join("#{name}.beam")
            |> File.write!(beam)
        end
      end
    end
  end

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

  def compile_forms(forms, opts \\ []) do
    Prelude.Compiler.compile_forms(forms, opts)
  end

  def compile_beam(beam, opts \\ []) do
    beam
    |> decompile_beam()
    |> compile_forms(opts)
  end

  def parse_transform(forms, _options) do
    compile_forms(forms, [out: :forms, single_module: true])
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
    case :beam_lib.chunks(beam, [:abstract_code]) do
      {:ok, {^module, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
        forms
      {:ok, {:no_debug_info, _}} ->
        throw({:forms_not_found, module})
      {:error, :beam_lib, {:file_error, _, :enoent}} ->
        throw({:module_not_found, module})
    end
  end
end
