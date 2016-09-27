defmodule Prelude do
  defmacro __using__(opts) do
    mod = Module.concat([:Etude, __CALLER__.module]) |> inspect() |> String.to_atom()
    quote do
      @after_compile Prelude
      @prelude_opts unquote([{:name, mod} | opts])

      def __etude__ do
        unquote(mod)
      end
    end
  end

  def __after_compile__(env, beam) do
    opts = Module.get_attribute(env.module, :prelude_opts)
    beam_file = compile_beam(beam, opts)
    name = opts[:name]

    Mix.Project.compile_path()
    |> Path.join("#{name}.beam")
    |> File.write!(beam_file)

    :ok
  end

  def compile_beam(beam, opts \\ []) do
    beam
    |> Prelude.Disassembler.disassemble!(opts)
    # |> Prelude.Debugger.print()
    |> Prelude.Tracker.track()
    |> Prelude.Status.Simple.transform()
    # |> Prelude.Transformer.transform(opts)
    |> Prelude.Assembler.assemble!()
  end
end
