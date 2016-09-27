defmodule Prelude.BeamFile do
  defstruct [:module,
             :exports,
             :info,
             :attrs,
             :code,
             :num_labels,
             :file,
             :beam,
             :name]

  def from_record({:beam_file, module, exports, attrs, info, code}) do
    %__MODULE__{
      module: module,
      exports: MapSet.new(exports),
      info: info,
      attrs: attrs,
      code: code
    }
  end

  def to_record(%{module: module, exports: exports, attrs: attrs, info: info, code: code}) do
    {:beam_file, module, MapSet.to_list(exports), attrs, info, code}
  end

  def fetch_chunks(%{beam: beam}, chunks) do
    chunks(beam, chunks, [])
  end
  def fetch_chunks(beam, chunks) do
    chunks(beam, chunks, [])
  end

  def get_chunks(%{beam: beam}, chunks) do
    chunks(beam, chunks, [:allow_missing_chunks])
  end
  def get_chunks(beam, chunks) do
    chunks(beam, chunks, [:allow_missing_chunks])
  end

  defp chunks(beam, chunks, opts) do
    case :beam_lib.chunks(beam, chunks, opts) do
      {:ok, {_, c}} ->
        Enum.reduce(c, %{}, fn
          ({key, :missing_chunk}, acc) ->
            Map.put(acc, key, nil)
          ({key, value}, acc) ->
            Map.put(acc, key, value)
        end)
    end
  end
end
