defmodule Prelude.Tracker do
  use Prelude.Transform

  defop label(lbl)

  defop func_info(module, function, arity)

  defop int_code_end()

  #
  # Function and BIF calls
  #

  defop call(fail, {_mod, fun, arity}) do
    #args = arity_range(arity) |> Enum.map(&get_register(state, &1))
    #state = put_call(state, fun, arity, args)
    #put_register(state, 0, %LocalCall{fun: fun, arity: arity, args: args})
    state
  end

  defop call_last(arity, label, deallocate)

  defop call_only(arity, label)

  defop call_ext(arity, destination)

  defop call_ext_last(arity, destination, deallocate)

  defop bif(bif, fail, [], reg)

  defop bif(fail, bif, [arg], reg)

  defop bif(fail, bif, [arg1, arg2], reg)

  #
  # Allocating, deallocating and returning.
  #

  defop allocate(stack_need, live)

  defop allocate_heap(stack_need, heap_need, live)

  defop allocate_zero(stack_need, live)

  defop allocate_heap_zero(stack_need, heap_need, live)

  defop test_heap(heap_need, live)

  defop init(stack_idx)

  defop deallocate(words)

  defop :return

  #
  # Sending & receiving.
  #

  defop :send

  defop :remove_message

  defop :timeout

  defop loop_rec(fail, source)

  defop loop_rec_end(label)

  defop wait(label)

  defop wait_timeout(label, time)

  #
  # Comparison operators
  #

  defop test(:is_lt, fail, [arg1, arg2])

  defop test(:is_ge, fail, [arg1, arg2])

  defop test(:is_eq, fail, [arg1, arg2])

  defop test(:is_ne, fail, [arg1, arg2])

  defop test(:is_eq_exact, fail, [arg1, arg2])

  defop test(:is_ne_exact, fail, [arg1, arg2])

  #
  # Type tests
  #

  defop test(:is_integer, fail, [arg])

  defop test(:is_float, fail, [arg])

  defop test(:is_number, fail, [arg])

  defop test(:is_atom, fail, [arg])

  defop test(:is_pid, fail, [arg])

  defop test(:is_reference, fail, [arg])

  defop test(:is_port, fail, [arg])

  defop test(:is_nil, fail, [arg])

  defop test(:is_binary, fail, [arg])

  defop test(:is_list, fail, [arg])

  defop test(:is_nonempty_list, fail, [arg])

  defop test(:is_tuple, fail, [arg])

  defop test(:test_arity, fail, [arg, arity])

  #
  # Indexing & jumping
  #

  defop select_val(arg, fail, destinations)

  defop select_tuple_arity(tuple, fail, destinations)

  defop jump(label)

  #
  # Catch
  #

  defop unquote(:"catch")(a, b)
  defop catch_end(a)

  #
  # Moving, extracting, modifying
  #

  defop move(source, destination)

  defop get_list(source, head, tail)

  defop get_tuple_element(source, element, destination)

  defop set_tuple_element(element, tuple, position)

  #
  # Building terms
  #

  defop put_list(a, b, c)
  defop put_tuple(a, b)
  defop put(a)

  #
  # Raising errors
  #

  defop badmatch(a)
  defop :if_end
  defop case_end(a)

  #
  # 'fun' support
  #

  defop call_fun(arity)

  defop test(:is_function, fail, [arg])

  #
  # R5
  #

  defop call_ext_only(arity, label)

  #
  # Binary construction (R7A)
  #
  defop bs_put_integer(a,b,c,d,e)
  defop bs_put_binary(a,b,c,d,e)
  defop bs_put_float(a,b,c,d,e)
  defop bs_put_string(a,b)

  #
  # Floating point arithmetic (R8)
  #

  defop :fclearerror
  defop fcheckerror(a)
  defop fmove(a,b)
  defop fconv(a,b)
  defop arithfbif(:fadd, fail, [fr1, fr2], to)
  defop arithfbif(:fsub, fail, [fr1, fr2], to)
  defop arithfbif(:fmul, fail, [fr1, fr2], to)
  defop arithfbif(:fdiv, fail, [fr1, fr2], to)
  defop arithfbif(:fnegate, fail, [fr1], to)

  #
  # New fun construction (R8)
  #

  defop make_fun2(a)
  defop make_fun2({_m, f, a}, _id, _uniq, capture)

  # Try/catch/raise (R8)

  defop unquote(:try)(a,b)
  defop try_end(a)
  defop try_case(a)
  defop try_case_end(a)
  defop unquote(:raise)(a,b)

  # R10B

  defop bs_init2(fail, size, words, reg, ff, dst)
  defop bs_add(fail, [first, second, size], to)
  defop apply(a)
  defop apply_last(a,b)

  defop test(:is_boolean, fail, [arg])

  defop test(:is_function2, fail, [arg, arity])

  #
  # New bit syntax matching in R11B
  #

  defop test(:bs_start_match2, fail, [src, size, unit, target])
  defop test(:bs_get_integer2, fail, [src, live, size, unit, ff, target])
  defop test(:bs_get_float2, fail, [src, live, size, unit, ff, targt])
  defop test(:bs_get_binary2, fail, [src, live, size, unit, ff, target])
  defop test(:bs_skip_bits2, fail, [reg, size, n, ff])
  defop test(:bs_test_tail2, fail, [reg, n])
  defop bs_save2(a,b)
  defop bs_restore(a,b)

  #
  # New GC bifs in R11B
  #

  # TODO get a list of these
  defop gc_bif(bif, fail, live, [arg], reg)
  defop gc_bif(bif, fail, live, [arg1, arg2], reg)

  # R11B-5
  defop test(:is_bitstr, fail, [arg])

  # R12B
  defop bs_context_to_binary(a)
  defop test(:bs_test_unit, fail, [reg, size])
  defop test(:bs_match_string, fail, [reg, size, string])
  defop :bs_init_writable
  defop bs_append(a,b,c,d,e,f,g,h)
  defop bs_private_append(a,b,c,d,e,f)

  defop trim(words, remaining)

  defop bs_init_bits(a,b,c,d,e,f)

  # R12B-5
  defop test(:bs_get_utf8, fail, [reg, live, ff, dst])
  defop test(:bs_skip_utf8, fail, [reg, live, ff])

  defop test(:bs_get_utf16, fail, [reg, live, ff, dst])
  defop test(:bs_skip_utf16, fail, [reg, live, ff])

  defop test(:bs_get_utf32, fail, [reg, live, ff, dst])
  defop test(:bs_skip_utf32, fail, [reg, live, ff])

  defop bs_utf8_size(a,b,c)
  defop bs_put_utf8(a,b,c)

  defop bs_utf16_size(a,b,c)
  defop bs_put_utf16(a,b,c)

  defop bs_put_utf32(a,b,c)

  # R13B03

  defop :on_load

  # R14A

  defop recv_mark(label)

  defop recv_set(label)

  defop gc_bif(fail, live, bif, [arg1, arg2, arg3], reg)

  # R15A

  defop line(n)

  # R17

  defop put_map_assoc(a,b,c,d,e)
  defop put_map_exact(a,b,c,d,e)
  defop test(:is_map, fail, [arg])
  defop test(:has_map_fields, fail, reg, fields)
  defop get_map_elements(fail, reg, elements)
end
