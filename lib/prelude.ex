defmodule Prelude do
  @vsn Mix.Project.config[:version]

  def compile_string(str, opts \\ []) do
    str
    |> Code.string_to_quoted!(opts)
    |> compile_quoted(opts)
  end

  def compile_quoted(quoted, opts \\ []) do
    env = :elixir.env_for_eval(opts)
    {{:block, line, calls}, env, scope} = :elixir.quoted_to_erl(quoted, env)
    {:block, line, Enum.map(calls, fn
      {:call, l1, {:remote, l2, {:atom, l3, :elixir_module}, {:atom, l4, :compile}}, args} ->
        {:call, l1, {:remote, l2, {:atom, l3, :"Elixir.Prelude.Compiler"}, {:atom, l4, :compile_elixir}}, args}
      other ->
        other
    end)}
    |> Prelude.Compiler.eval_forms(env, scope)
    |> compile_forms(opts)
  end

  def compile_forms(forms, opts \\ []) do
    Prelude.Compiler.compile_erlang(forms, opts)
  end

  def parse_transform(forms, _options) do
    compile_forms(forms, [out: :forms])
  end

  defmacro defetude(name, block) do
    quote bind_quoted: [name: Macro.escape(name),
                        block: Macro.escape(block)] do
      Prelude.compile_quoted({:defmodule, [import: Kernel], [name, block]})
    end
  end
end
