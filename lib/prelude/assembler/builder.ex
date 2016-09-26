defmodule Prelude.Assembler.Builder do
  alias :beam_dict, as: Dict
  alias Prelude.Assembler.Encoder

  def build(code, dict, beam_file) do
    essentials = [
      build_atom_chunk(dict),
      build_code_chunk(code, dict, beam_file),
      build_string_chunk(dict),
      build_import_chunk(dict),
      build_export_chunk(dict),
      build_lambda_chunk(dict),
      build_literal_chunk(dict)
    ]

    local_chunk = build_local_chunk(dict)
    line_chunk = chunk("Line", build_line_table(dict))

    md5 = module_md5(essentials)
    essentials = finalize_fun_table(essentials, md5)

    {attributes, compile} = build_attributes(beam_file, md5)

    attr_chunk = chunk("Attr", attributes)
    compile_chunk = chunk("CInf", compile)

    additional = Prelude.BeamFile.get_chunks(beam_file, ['Abst', 'ExDc'])
    |> Enum.map(fn
      ({_, nil}) ->
        []
      ({key, value}) ->
        chunk(:erlang.list_to_binary(key), value)
    end)

    build_form("BEAM", [
      essentials,
      local_chunk,
      attr_chunk,
      compile_chunk,
      additional,
      line_chunk
    ])
  end

  defp build_form(id, chunks) when byte_size(id) == 4 and is_list(chunks) do
    chunks = :erlang.list_to_binary(chunks)
    size = byte_size(chunks)
    0 = rem(size, 4)
    <<"FOR1", (size + 4) :: 32, id :: binary, chunks :: binary>>
  end

  defp build_code_chunk(code, dict, %{code: funcs, num_labels: num_labels}) do
    chunk(
      "Code",
      <<16 :: 32,
      (:beam_opcodes.format_number()) :: 32,
      (Dict.highest_opcode(dict)) :: 32,
      num_labels :: 32,
      (length(funcs)) :: 32>>,
      code
    )
  end

  defp build_atom_chunk(dict) do
    {num, tab} = Dict.atom_table(dict)
    chunk(
      "Atom",
      << num :: 32 >>,
      tab
    )
  end

  defp build_import_chunk(dict) do
    {num, tab} = Dict.import_table(dict)
    chunk(
      "ImpT",
      << num :: 32 >>,
      flatten(tab)
    )
  end

  defp build_export_chunk(dict) do
    {num, tab} = Dict.export_table(dict)
    chunk(
      "ExpT",
      << num :: 32 >>,
      flatten(tab)
    )
  end

  defp build_local_chunk(dict) do
    {num, tab} = Dict.local_table(dict)
    chunk(
      "LocT",
      << num :: 32 >>,
      flatten(tab)
    )
  end

  defp build_string_chunk(dict) do
    {_, tab} = Dict.string_table(dict)
    chunk(
      "StrT",
      tab
    )
  end

  defp build_lambda_chunk(dict) do
    case Dict.lambda_table(dict) do
      {0,[]} ->
        <<>>
      {num, tab} ->
        chunk(
          "FunT",
          << num :: 32 >>,
          tab
        )
    end
  end

  def build_literal_chunk(dict) do
    case Dict.literal_table(dict) do
      {0, []} ->
        <<>>
      {num, tab} ->
        tab = [<<num :: 32>>, tab]
        size = :erlang.iolist_size(tab)
        chunk(
          "LitT",
          << size :: 32 >>,
          :zlib.compress(tab)
        )
    end
  end

  def build_line_table(dict) do
    {num_line_instrs, num_fnames, fnames, num_lines, lines} = Dict.line_table(dict)
    num_fnames = num_fnames - 1
    [_ | fnames] = fnames
    fnames = Enum.map(fnames, fn(f) ->
      f = :unicode.characters_to_binary(f)
      <<byte_size(f) :: 16, f :: binary>>
    end) |> :erlang.iolist_to_binary()
    lines = lines |> encode_line_items(0) |> :erlang.iolist_to_binary()
    ver = 0
    bits = 0
    <<ver :: 32, bits :: 32, num_line_instrs :: 32, num_lines :: 32, num_fnames :: 32,
      lines :: binary, fnames :: binary>>
  end

  defp encode_line_items([], _) do
    []
  end
  defp encode_line_items([{f, l} | t], f) do
    [Encoder.encode_type(:i, l) | encode_line_items(t, f)]
  end
  defp encode_line_items([{f, l} | t], _) do
    [Encoder.encode_type(:a, l), Encoder.encode_type(:i, l) | encode_line_items(t, f)]
  end

  defp chunk(id, contents) do
    chunk(id, <<>>, contents)
  end

  defp chunk(id, head, contents) when byte_size(id) == 4 and is_binary(head) and is_binary(contents) do
    size = byte_size(head) + byte_size(contents)
    [<<id :: binary, size :: 32, head :: binary>>, contents | pad(size)]
    |> :erlang.iolist_to_binary()
  end
  defp chunk(id, head, contents) when is_list(contents) do
    contents = :erlang.iolist_to_binary(contents)
    chunk(id, head, contents)
  end

  defp pad(size) do
    case rem(size, 4) do
      0 -> []
      rem -> :lists.duplicate(4 - rem, 0)
    end
  end

  defp flatten(list) do
    list
    |> Enum.map(fn({m, f, a}) ->
      << m :: 32, f :: 32, a :: 32>>
    end)
    |> :erlang.list_to_binary()
  end

  defp module_md5(essentials) do
    essentials = filter_essentials(essentials)
    :crypto.hash(:md5, essentials)
  end

  defp filter_essentials([]) do
    []
  end
  defp filter_essentials([<<>> | t]) do
    filter_essentials(t)
  end
  defp filter_essentials([<< _tag :: size(4)-binary, sz :: 32, data :: size(sz)-binary, _ :: binary>> | rest]) do
    [data | filter_essentials(rest)]
  end

  defp finalize_fun_table(essentials, md5) do
    Enum.map(essentials, &finalize_fun_table_1(&1, md5))
  end

  defp finalize_fun_table_1(<<"FunT", keep :: size(8)-binary, tab :: binary>>, md5) do
    <<uniq :: 27, _ :: size(101)-bits>> = md5
    tab = finalize_fun_table_2(tab, uniq, <<>>)
    <<"FunT", keep :: binary, tab :: binary>>
  end
  defp finalize_fun_table_1(chunk, _) do
    chunk
  end

  defp finalize_fun_table_2(<<>>, _, acc) do
    acc
  end
  defp finalize_fun_table_2(<<keep :: size(20)-binary, 0 :: 32, t :: binary>>, uniq, acc) do
    finalize_fun_table_2(t, uniq, <<acc :: binary, keep :: binary, uniq :: 32>>)
  end

  defp build_attributes(%{attrs: attrs, file: file}, md5) do
    compile = [{:options, []}, {:version, 0.1}, {:source, to_charlist(file)}]
    attrs = Keyword.put(attrs, :vsn, md5)
    {:erlang.term_to_binary(attrs), :erlang.term_to_binary(compile)}
  end
end
