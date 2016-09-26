defmodule Prelude.Debugger do
  @ignore [__info__: 1, __etude__: 0, module_info: 0, module_info: 1]

  def print(thing, ignore \\ @ignore)
  def print(beam, ignore) when is_binary(beam) do
    {:beam_file, _, _, _, _, code} = :beam_disasm.file(beam)
    print(code, ignore)
    beam
  end
  def print({:beam_file, _, _, _, _, code} = f, ignore) do
    print(code, ignore)
    f
  end
  def print(%{code: code} = m, ignore) do
    print(code, ignore)
    m
  end
  def print(code, ignore) do
    Enum.each(code, fn
      ({:function, name, arity, _, code} = f) ->
        if {name, arity} in ignore do
          nil
        else
          debug(f)
          Enum.each(code, &debug/1)
        end
    end)
    IO.puts ""
    code
  end

  def debug(instr) do
    :io.format('> ')
    case instr do
      {:function, name, arity, entry, _code} ->
        {:function, name, arity, entry}
      {:label, _} ->
        :io.format('  ')
        instr
      _ ->
        :io.format('    ')
        instr
    end
    |> IO.inspect(width: :infinity)
  end
end
