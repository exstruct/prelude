defmodule Prelude.Assembler.Encoder do
  use Bitwise
  alias :beam_dict, as: Dict
  import :beam_asm, only: [encode: 2]

  @tag_u 0
  @tag_i 1
  @tag_a 2
  @tag_x 3
  @tag_y 4
  @tag_f 5
  @tag_h 6
  @tag_z 7

  def encode(code, exports, dict, beam_file) do
    exports = MapSet.new(exports)
    encode(code, exports, dict, beam_file, [])
  end

  def encode_type(:i, v) do
    encode(@tag_i, v)
  end
  def encode_type(:a, v) do
    encode(@tag_a, v)
  end

  defp encode([], _, dict, beam_file, acc) do
    {int_code_end, dict} = make_op(:int_code_end, dict, beam_file)
    {:erlang.list_to_binary(:lists.reverse(acc, [int_code_end])), dict}
  end
  defp encode([{:function, name, arity, entry, asm} | rest], exports, dict, beam_file, acc) do
    dict =
    if MapSet.member?(exports, {name, arity}) do
      Dict.export(name, arity, entry, dict)
    else
      Dict.local(name, arity, entry, dict)
    end

    {code, dict} = assemble_function(asm, acc, dict, beam_file)
    encode(rest, exports, dict, beam_file, code)
  end

  defp assemble_function([], acc, dict, _) do
    {acc, dict}
  end
  defp assemble_function([h | t], acc, dict, beam_file) do
    {code, dict} = make_op(h, dict, beam_file)
    assemble_function(t, [code | acc], dict, beam_file)
  end

  defp make_op({:%, _}, dict, _) do
    {[], dict}
  end
  defp make_op({:line, l}, dict, %{file: f} = beam_file) when is_integer(l) do
    make_op({:line, [{:location, f, l}]}, dict, beam_file)
  end
  defp make_op({:line, l}, dict, _) do
    {index, dict} = Dict.line(l, dict)
    encode_op(:line, [index], dict)
  end
  defp make_op({:bif, bif, {:f, _}, [], dest}, dict, _) do
    encode_op(:bif0, [{:extfunc, :erlang, bif, 0}, dest], dict)
  end
  defp make_op({:bif, :raise, _, [_, _] = args, _dest}, dict, _) do
    encode_op(:raise, args, dict)
  end
  defp make_op({:bif, bif, fail, args, dest}, dict, beam_file) do
    arity = length(args)
    case bif_type(bif, arity) do
      {:op, op} ->
        make_op(:erlang.list_to_tuple([op, fail | args ++ [dest]]), dict, beam_file)
      bif_op when is_atom(bif_op) ->
        encode_op(bif_op, [fail, {:extfunc, :erlang, bif, arity} | args ++ [dest]], dict)
    end
  end
  defp make_op({:gc_bif, bif, fail, live, args, dest}, dict, _) do
    arity = length(args)
    op = case arity do
           1 -> :gc_bif1
           2 -> :gc_bif2
           3 -> :gc_bif3
         end
    encode_op(op, [fail, live, {:extfunc, :erlang, bif, arity} | args ++ [dest]], dict)
  end
  defp make_op({:test, cond, fail, src, {:list, _} = ops}, dict, _) do
    encode_op(cond, [fail, src, ops], dict)
  end
  defp make_op({:test, cond, fail, ops}, dict, _) do
    encode_op(cond, [fail | ops], dict)
  end
  defp make_op({:test, cond, fail, live, [op | ops], dst}, dict, _) when is_list(ops) do
    encode_op(cond, [fail, op, live | ops ++ [dst]], dict)
  end
  defp make_op({:make_fun2, {:f, lbl}, _index, _uniq, num_free}, dict, beam_file) do
    {fun, dict} = Dict.lambda(lbl, num_free, dict)
    make_op({:make_fun2, fun}, dict, beam_file)
  end
  defp make_op({:make_fun2, {mod, f, a}, _index, _uniq, num_free}, dict, %{module: mod, code: code} = beam_file) do
    lbl = label_for_fa(f, a, beam_file)
    {fun, dict} = Dict.lambda(lbl, num_free, dict)
    make_op({:make_fun2, fun}, dict, beam_file)
  end
  defp make_op({name, a, {mod, f, a}}, dict, %{module: mod} = beam_file) when name in [:call, :call_only] do
    lbl = label_for_fa(f, a, beam_file)
    make_op({name, a, {:f, lbl}}, dict, beam_file)
  end
  defp make_op({:call_last, a, {mod, f, a}, deallocate}, dict, %{module: mod} = beam_file) do
    lbl = label_for_fa(f, a, beam_file)
    make_op({:call_last, a, {:f, lbl}, deallocate}, dict, beam_file)
  end
  defp make_op(op, dict, _) when is_atom(op) do
    encode_op(op, [], dict)
  end

  for l <- 1..8 do
    vars = 1..l |> Enum.map(&Macro.var(:"arg_#{&1}", nil))
    match = {:{}, [], [Macro.var(:name, nil) | vars]}
    defp make_op(unquote(match), dict, _) do
      encode_op(var!(name), unquote(vars), dict)
    end
  end

  defp encode_op(name, args, dict) when is_atom(name) do
    op = :beam_opcodes.opcode(name, length(args))
    dict = Dict.opcode(op, dict)
    encode_op_args(args, dict, op)
  end

  defp encode_op_args([], dict, acc) do
    {acc, dict}
  end
  defp encode_op_args([a | args], dict, acc) do
    {a, dict} = encode_arg(a, dict)
    encode_op_args(args, dict, [acc, a])
  end

  defp encode_arg({:x, x}, dict) when is_integer(x) and x >= 0 do
    {encode(@tag_x, x), dict}
  end
  defp encode_arg({:y, y}, dict) when is_integer(y) and y >= 0 do
    {encode(@tag_y, y), dict}
  end
  defp encode_arg({:atom, atom}, dict) when is_atom(atom) do
    {index, dict} = Dict.atom(atom, dict)
    {encode(@tag_a, index), dict}
  end
  defp encode_arg({:integer, n}, dict) do
    {encode(@tag_i, n), dict}
  end
  defp encode_arg(nil, dict) do
    {encode(@tag_a, 0), dict}
  end
  defp encode_arg({:f, w}, dict) do
    {encode(@tag_f, w), dict}
  end
  defp encode_arg({:string, s}, dict) do
    {offset, dict} = Dict.string(s, dict)
    {encode(@tag_u, offset), dict}
  end
  defp encode_arg({:extfunc, m, f, a}, dict) do
    {index, dict} = Dict.import(m, f, a, dict)
    {encode(@tag_u, index), dict}
  end
  defp encode_arg({:list, list}, dict) do
    {l, dict} = encode_list(list, dict, [])
    {[encode(@tag_z, 1), encode(@tag_u, length(list)) | l], dict}
  end
  defp encode_arg({:float, float}, dict) when is_float(float) do
    encode_arg({:literal, float}, dict)
  end
  defp encode_arg({:fr, fr}, dict) do
    {[encode(@tag_z, 2), encode(@tag_u, fr)], dict}
  end
  defp encode_arg({:field_flags, flags}, dict) do
    flags = Enum.reduce(flags, 0, &(&2 ||| flag_to_bit(&1)))
    {encode(@tag_u, flags), dict}
  end
  defp encode_arg({:alloc, list}, dict) do
    encode_alloc_list(list, dict)
  end
  defp encode_arg({:literal, lit}, dict) do
    {index, dict} = Dict.literal(lit, dict)
    {[encode(@tag_z, 4), encode(@tag_u, index)], dict}
  end
  defp encode_arg(int, dict) when is_integer(int) do
    {encode(@tag_u, int), dict}
  end

  defp encode_list([], dict, acc) do
    {acc, dict}
  end
  defp encode_list([h | t], dict, acc) when not is_list(h) do
    {enc, dict} = encode_arg(h, dict)
    encode_list(t, dict, [acc, enc])
  end

  flags = %{
    little: 0x02,
    big: 0x00,
    signed: 0x04,
    unsigned: 0x00,
    native: 0x10,
  }

  for {f, e} <- flags do
    defp flag_to_bit(unquote(f)), do: unquote(e)
  end
  defp flag_to_bit({:anno, _}), do: 0

  defp encode_alloc_list(l, dict) do
    nil
  end

  bifs = [
    {:fnegate, 1},
    {:fadd, 2},
    {:fsub, 2},
    {:fmul, 2},
    {:fdiv, 2},
  ]

  for {name, arity} <- bifs do
    defp bif_type(unquote(name), unquote(arity)), do: {:op, unquote(name)}
  end
  defp bif_type(_, 1), do: :bif1
  defp bif_type(_, 2), do: :bif2

  defp label_for_fa(f, a, %{code: code}) do
    Enum.find_value(code, fn
      ({:function, ^f, ^a, l, _}) -> l
      (_) -> false
    end)
  end
end
