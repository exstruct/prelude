defmodule Test.Prelude.BeamInstr do
  use Test.Prelude.Case

  preludetest "call/2" do
    def test() do
      a = number()
      a + a
    end

    defp number() do
      ok(1)
    end
  end

  preludetest "call_last/2" do
    def test() do
      number()
    end

    defp number() do
      ok(1)
    end
  end

  preludetest "call_only/2" do
    def test() do
      loop(ok(5))
    end

    defp loop(0) do
      :END!
    end
    defp loop(n) do
      loop(n - 1)
    end
  end

  preludetest "call_ext/2" do
    def test() do
      a = ok(1)
      a + a
    end
  end

  preludetest "call_ext_last/3" do
    def test() do
      ok(1)
    end
  end

  preludetest "bif0/2" do
    def test() do
      {self(), node()}
    end
  end

  preludetest "bif1/4" do
    def test() do
      {is_integer(ok(1)), is_binary(ok("foo"))}
    end
  end

  preludetest "bif2/5" do
    def test() do
      elem(ok({1,2,3}), 0)
    end
  end

  # TODO message passing

  preludetest "is_lt/3" do
    def test() do
      local(ok(1))
    end

    defp local(a) when a < 2 do
      a
    end
    defp local(_) do
      nil
    end
  end

  preludetest "is_ge/3" do
    def test() do
      local(ok(2))
    end

    defp local(a) when a >= 2 do
      a
    end
    defp local(_) do
      nil
    end
  end

  preludetest "is_eq/3" do
    def test() do
      local(ok(1.0))
    end

    defp local(a) when a == 1 do
      a
    end
    defp local(_) do
      nil
    end
  end

  preludetest "is_ne/3" do
    def test() do
      local(ok(3.0))
    end

    defp local(a) when a != 3 do
      a
    end
    defp local(_) do
      nil
    end
  end

  preludetest "is_eq_exact/3" do
    def test() do
      local(ok(1))
    end

    defp local(a) when a === 1 do
      a
    end
    defp local(_) do
      nil
    end
  end

  preludetest "is_ne_exact/3" do
    def test() do
      local(ok(3))
    end

    defp local(a) when a !== 3 do
      a
    end
    defp local(_) do
      nil
    end
  end

  preludetest "is_integer/2" do
    def test() do
      case ok(1) do
        a when is_integer(a) ->
          true
      end
    end
  end

  preludetest "is_float/2" do
    def test() do
      case ok(1.0) do
        a when is_float(a) ->
          true
      end
    end
  end

  preludetest "is_number/2" do
    def test() do
      case ok(1.0) do
        a when is_number(a) ->
          true
      end
    end
  end

  preludetest "is_atom/2" do
    def test() do
      case ok(:foo) do
        a when is_atom(a) ->
          true
      end
    end
  end

  preludetest "is_pid/2" do
    def test() do
      case ok(self()) do
        a when is_pid(a) ->
          true
      end
    end
  end

  preludetest "is_reference/2" do
    def test() do
      case ok(:erlang.make_ref()) do
        a when is_reference(a) ->
          true
      end
    end
  end

  # TODO is_port/2

  preludetest "is_nil/2" do
    def test() do
      case ok([]) do
        [] ->
          true
      end
    end
  end

  preludetest "is_binary/2" do
    def test() do
      case ok("Bin") do
        a when is_binary(a) ->
          true
      end
    end
  end

  preludetest "is_list/2" do
    def test() do
      case ok([1,2,3]) do
        a when is_list(a) ->
          true
      end
    end
  end

  preludetest "is_nonempty_list/2" do
    def test() do
      case ok([1,2,3]) do
        [_ | _] ->
          true
      end
    end
  end

  preludetest "is_tuple/2" do
    def test() do
      case ok({1,2,3}) do
        a when is_tuple(a) ->
          true
      end
    end
  end

  preludetest "test_arity/3" do
    def test() do
      {_, _, _} = ok({1,2,3})
      :ok
    end
  end

  # TODO select_val/3
  # TODO select_tuple_arity/3
  # TODO jump

  # TODO catch/2

  preludetest "get_list/3" do
    def test() do
      [_h | t] = ok([1,2,3])
      t
    end
  end

  preludetest "get_tuple_element/3" do
    def test() do
      {a, _, _} = ok({1,2,3})
      a
    end
  end

  # TODO set_tuple_element

  preludetest "put_list/3" do
    def test() do
      a = ok(1)
      b = ok([2,3])
      [a | b]
    end
  end

  preludetest "put_tuple/2 and put/1" do
    def test() do
      {ok(1), ok(2), ok(3)}
    end
  end

  preludetest "badmatch/1" do
    def test() do
      1 = ok(2)
    end
  end

  preludetest "if_end" do
    def test() do
      cond do
        ok(false) ->
          :foo
      end
    end
  end

  preludetest "case_end" do
    def test() do
      case ok(1) do
        2 ->
          :bar
      end
    end
  end

  preludetest "call_fun/1 make_fun/1" do
    def test() do
      fun = ok(fn -> :hello end)
      fun2 = ok(fn(a, b) -> [a, b] end)
      {fun.(), fun2.(1, 2)}
    end
  end

  preludetest "is_function/2" do
    def test() do
      local(ok(fn -> :hello end))
    end

    defp local(f) when is_function(f) do
      true
    end
    defp local(_) do
      false
    end
  end

  preludetest "call_ext_only/2" do
    def test() do
      local(ok(1))
    end

    def local(0) do
      :DONE
    end
    def local(n) do
      __MODULE__.local(n - 1)
    end
  end

  preludetest "bs_put_integer/5" do
    def test() do
      int = ok(1)
      << int :: 32 >>
    end
  end

  preludetest "bs_put_binary/5" do
    def test() do
      bin = ok("Hello")
      << bin :: binary >>
    end
  end

  preludetest "bs_put_float/5" do
    def test() do
      int = ok(2.0)
      << int :: size(32)-float >>
    end
  end

  preludetest "bs_put_string/5" do
    def test() do
      bin = ok("Hello, ")
      << bin :: binary, "Joe" >>
    end
  end

  preludetest "fadd/4" do
    def test() do
      1.0 + ok(3.0)
    end
  end

  preludetest "fsub/4" do
    def test() do
      1.0 - ok(3.0)
    end
  end

  preludetest "fmul/4" do
    def test() do
      1.0 * ok(3.0)
    end
  end

  preludetest "fdiv/4" do
    def test() do
      1.0 / ok(3.0)
    end
  end

  preludetest "fnegate/3" do
    def test() do
      -(1.0 + ok(1.0))
    end
  end

  preludetest "make_fun2/1" do
    def test() do
      a = 1
      fn(b) -> a + b end
    end
  end

  preludetest "try/2 and try_end/1" do
    def test() do
      try do
        error(:error)
      catch
        _, _ ->
          :CAUGHT
      end
    end
  end

  # TODO try_case/1 try_case_end/1

  preludetest "raise/2" do
    def test() do
      try do
        raise ok(CompileError)
      rescue
        _e ->
          :CAUGHT
      end
    end
  end

  preludetest "bs_init2/6 bs_add/5" do
    def test() do
      bin = ok(<<"Hello">>)
      bin2 = ok(<<"World">>)
      <<bin :: binary, bin2 :: binary>>
    end
  end

  preludetest "apply/1" do
    def test() do
      mod = ok(:erlang)
      fun = ok(:+)
      args = ok([1,2])
      {apply(mod, fun, args), apply(mod, fun, args)}
    end
  end

  preludetest "apply_last/2" do
    def test() do
      mod = ok(:erlang)
      fun = ok(:+)
      args = ok([1,2])
      apply(mod, fun, args)
    end
  end

  preludetest "is_boolean/2" do
    def test() do
      {local(ok(true)), local(ok(true)), local(ok(1))}
    end

    defp local(a) when is_boolean(a) do
      :BOOL
    end
    defp local(_) do
      :NOT
    end
  end

  preludetest "is_function/3" do
    def test() do
      f1 = fn(_) -> 1 end |> ok()
      f2 = fn(_, _) -> 2 end |> ok()
      {local(f1), local(f2)}
    end

    defp local(f) when is_function(f, 2) do
      :TWO
    end
    defp local(_f) do
      :OTHER
    end
  end

  # bs_start_match2/5 bs_get_integer2/7 bs_get_float2/7 bs_get_binary2/7 bs_skip_bits2/5
  preludetest "bs_match instrs" do
    def test() do
      <<i :: 8, f :: size(32)-float, _ :: 8, b :: binary>> =
        ok(<<1 :: 8, 1.0 :: size(32)-float, "Thing" :: binary>>)
      {i, f, b}
    end
  end

  # TODO bs_save2/2 bs_restore2/2

  preludetest "gc_bif1/5" do
    def test() do
      -ok(1)
    end
  end

  preludetest "gc_bif2/6" do
    def test() do
      div(ok(1) + ok(3) * ok(5) - ok(6), ok(9))
    end
  end

  preludetest "is_bitstr/2" do
    def test() do
      is_bitstring(<<1 :: 1, 0 :: 1>>)
    end
  end

  # TODO more binary
  preludetest "bs_match_string/4" do
    def test() do
      case ok("Hell") do
        "Hello" ->
          :hello
        "Hell" ->
          :oh_no!
      end
    end
  end

  preludetest "utf8" do
    def test() do
      l = ok("ł")
      << _ :: utf8, _ :: utf8, l :: utf8, _ :: binary>> = ok(<<"heł", l :: utf8, "o">>)
      l
    end
  end

  # TODO utf16 and utf32

  # TODO gc_bif3/7

  preludetest "put_map_assoc/5" do
    def test() do
      %{ok("foo") => ok("bar"), "baz" => "bang"}
    end
  end

  preludetest "put_map_exact/5" do
    def test() do
      map = ok(%{ok("foo") => ok("bar"), "baz" => "bang"})
      %{map | ok("foo") => ok(1), ok("baz") => ok(2)}
    end
  end

  preludetest "is_map/2" do
    def test() do
      b = ok(1)
      is_map(b)
    end
  end

  preludetest "has_map_fields/3" do
    def test() do
      foo = ok("foo")
      %{^foo => _,
        "baz" => _} = ok(%{ok("foo") => ok("bar"), "baz" => true})
    end
  end

  preludetest "get_map_elements/3" do
    def test() do
      foo = ok("foo")
      %{^foo => bar,
        "baz" => baz} = ok(%{ok("foo") => ok("bar"), "baz" => ok(true)})
      {bar, baz}
    end
  end
end
