defmodule Prelude.Etude do
  @ignore [__info__: 1, module_info: 0, module_info: 1, __etude__: 0]

  @unsafe Prelude.Status.UNSAFE
  @safe Prelude.Status.SAFE

  def transform(%{typed_code: code} = module) do
    # code = Enum.map(code, &function(&1, module))
    %{module | typed_code: code}
  end

  # defp function(%{name: n, arity: a} = f, _) when {n, a} in @ignore do
  #   f
  # end
  # defp function(%{code: labels} = f, _) do
  #   code = labels
  #   |> Stream.map(fn({lbl, ops}) ->
  #     # IO.puts "=== #{lbl} ==="
  #     ops = Enum.map(ops, &map_op/1)
  #     Enum.each(ops, &print/1)
  #     {lbl, ops}
  #   end)
  #   |> Enum.into(%{})

  #   %{f | code: code}
  # end

  # defp map_op(%{op: {:bs_append, _, size, _, _, _, from, _, to}} = op) do
  #   maybe_put_unsafe(op, [size, from])
  # end
  # defp map_op(%{op: {:test, _name, _fail, [{_, _} = arg]}} = op) do
  #   maybe_put_unsafe(op, [arg])
  # end
  # defp map_op(%{op: {:test, _name, _fail, [{_, _}, {_, _}] = args}} = op) do
  #   maybe_put_unsafe(op, args)
  # end
  # defp map_op(%{op: o} = op) when elem(o, 0) in [:apply, :apply_last] do
  #   arity = elem(o, 1)
  #   args = arity_range(arity + 2) |> Enum.map(&({:x, &1}))
  #   maybe_put_unsafe(op, args)
  # end
  # defp map_op(op) do
  #   op
  # end

  # defp print(%{op: o, info: info} = op) do
  #   # :io.format('*X      ')
  #   # IO.inspect info.status.registers
  #   # :io.format('*Y      ')
  #   # IO.inspect info.status.stack
  #   case Map.fetch(info, :etude) do
  #     {:ok, v} ->
  #       :io.format('**      ')
  #       IO.inspect v
  #     _ ->
  #       nil
  #   end
  #   Prelude.Debugger.debug(o)
  #   op
  # end

  # defp get_register(%{status: %{registers: rgs}}, r) do
  #   {:ok, value} = Map.fetch(rgs, r)
  #   value
  # rescue
  #   MatchError ->
  #     throw {:undefined_register, r, rgs}
  # end
  # defp get_stack(%{status: %{stack: stack}}, s) do
  #   {:ok, value} = Map.fetch(stack, s)
  #   value
  # end

  # defp get_value(info, {:x, n}) do
  #   get_register(info, n)
  # end
  # defp get_value(info, {:y, n}) do
  #   get_stack(info, n)
  # end
  # defp get_value(_, {type, _}) when type in [:atom, :integer, :literal] do
  #   @safe
  # end

  # defp maybe_put_unsafe(%{info: info} = op, args) do
  #   case fetch_unsafe(info, args) do
  #     [] ->
  #       op
  #     unsafe ->
  #       %{op | info: Map.put(info, :etude, unsafe)}
  #   end
  # end

  # defp fetch_unsafe(info, inputs) do
  #   inputs
  #   |> Enum.filter(fn(key) ->
  #     get_value(info, key) == @unsafe
  #   end)
  # end

  # defp arity_range(0), do: []
  # defp arity_range(n), do: 0..(n - 1)
end
