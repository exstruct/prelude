defmodule Prelude.Disassembler do
  use Bitwise

  def disassemble!(beam, opts \\ []) do
    beam
    |> file()
    |> add_beam_info(beam, opts)
    |> fix_exports()
    |> count_labels()
  end

  defp file(beam) do
    beam
    |> :beam_disasm.file()
    |> Prelude.BeamFile.from_record()
  end

  defp fix_exports(%{exports: exports} = beam) do
    exports = exports
    |> Stream.map(fn({n, a, _}) ->
      {n, a}
    end)
    |> Enum.into(MapSet.new())
    %{beam | exports: exports}
  end

  defp add_beam_info(%{info: info, module: module} = beam_file, beam, opts) do
    %{beam_file | beam: beam, file: info[:source], name: opts[:name] || module}
  end

  defp count_labels(module = %{code: code}) do
    labels = code
    |> List.last()
    |> elem(4)
    |> Enum.reduce(0, fn
      ({:label, l}, _) -> l
      (_, l) -> l
    end)
    %{module | num_labels: labels + 1}
  end
end
