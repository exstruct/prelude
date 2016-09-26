defmodule Prelude.Assembler do
  alias :beam_dict, as: Dict
  alias __MODULE__.{Encoder,Builder}

  def assemble!(beam_file) do
    %{name: name, exports: exports, code: code, file: file} = beam_file
    {1, dict} = Dict.atom(name, Dict.new())
    {0, dict} = Dict.fname(to_charlist(file), dict)

    # TODO on_load?
    {code, dict} = Encoder.encode(code, exports, dict, beam_file)
    Builder.build(code, dict, beam_file)
  end
end
