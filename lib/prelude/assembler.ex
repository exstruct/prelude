defmodule Prelude.Assembler do
  alias Prelude.BeamFile

  def assemble!(beam_file) do
    beam_file
    |> fix_weird_stuff()
    |> BeamFile.export()
    |> pass(passes())
    |> post_fixes()
    |> beam_asm(beam_file)
  end

  defp pass(code, []) do
    code
  end
  defp pass(code, [pass | passes]) do
    case pass.module(code, []) do
      {:ok, code} ->
        pass(code, passes)
    end
  end

  defp beam_asm(code, %{file: source} = beam_file) do
    %{'Abst' => abst} = BeamFile.get_chunks(beam_file, ['Abst'])
    {:ok, code} = :beam_asm.module(code, abst, source, [])
    code
  end

  defp passes() do
    [
      :beam_a,
      :beam_block,
      :beam_except,
      :beam_bool,
      :beam_type,
      :beam_split,
      :beam_dead,
      :beam_jump,
      :beam_peep,
      :beam_clean,
      :beam_bsm,
      :beam_receive,
      :beam_trim,
      :beam_flatten,
      :beam_z,
      :beam_validator
    ]
  end

  defp fix_weird_stuff(%{code: code} = beam_file) do
    labels = local_labels(code)
    code = Enum.map(code, &fix_function_weird_stuff(&1, labels, beam_file))
    %{beam_file | code: code}
  end

  defp fix_function_weird_stuff({:function, _, _, _, [{:line, _} = li, {:label, _} = la | ops]} = f, labels, file) do
    fix_function_weird_stuff(put_elem(f, 4, [la, li | ops]), labels, file)
  end
  defp fix_function_weird_stuff({:function, _, _, _, ops} = f, labels, %{module: m, file: file}) do
    ops = Enum.map(ops, fn
      ({:line, l}) when is_integer(l) ->
        {:line, [{:location, file, l}]}
      ({name, a, {^m, f, a}}) when name in [:call, :call_only] ->
        {:ok, l} = Map.fetch(labels, {f, a})
        {name, a, {:f, l}}
      ({:call_last, a, {^m, f, a}, rel}) ->
        {:ok, l} = Map.fetch(labels, {f, a})
        {:call_last, a, {:f, l}, rel}
      ({:test, :bs_start_match2, fail, [reg, live, max, ms]}) ->
        {:test, :bs_start_match2, fail, live, [reg, max], ms}
      ({:test, :bs_get_integer2, fail, [ctx, live, size, unit, ff, dst]}) ->
        {:test, :bs_get_integer2, fail, live, [ctx, size, unit, ff], dst}
      ({:make_fun2, {^m, f, a}, index, uniq, num_free} = op) ->
        {:ok, l} = Map.fetch(labels, {f, a})
        {:make_fun2, {:f, l}, index, uniq, num_free}
      (op) ->
        op
    end)
    put_elem(f, 4, ops)
  end

  defp local_labels(code) do
    Enum.reduce(code, %{}, fn({:function, n, a, entry, _}, acc) ->
      Map.put(acc, {n, a}, entry)
    end)
  end

  defp post_fixes({_, _, _, code, _} = m) do
    code = Enum.map(code, &post_fixes_function/1)
    put_elem(m, 3, code)
  end

  defp post_fixes_function({:function, _, _, _, ops} = f) do
    ops = Enum.map(ops, fn
      ({:bs_init2, fail, size, words, reg, ff, dst}) ->
        {:bs_init2, fail, size, words, reg, encode_ff(ff), dst}
      ({:bs_put_binary, fail, size, u, ff, src}) ->
        {:bs_put_binary, fail, size, u, encode_ff(ff), src}
      ({:bs_append, fail, size, extra, live, unit, bin, ff, dst}) ->
        {:bs_append, fail, size, extra, live, unit, bin, encode_ff(ff), dst}
      ({:test, :bs_match_string, fail, [reg, size, string]}) ->
        {:test, :bs_match_string, fail, [reg, size, {:string, to_charlist(string)}]}
      ({:test, :bs_get_integer2, fail, live, [ctx, size, unit, ff], dst}) ->
        {:test, :bs_get_integer2, fail, live, [ctx, size, unit, encode_ff(ff)], dst}
      (op) ->
        op
    end)
    put_elem(f, 4, ops)
  end

  defp encode_ff({:field_flags, ff}) do
    {:field_flags, encode_ff(ff)}
  end
  defp encode_ff(0) do
    []
  end
end
