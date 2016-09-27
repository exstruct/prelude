defmodule Prelude.Status.Simple do
  alias Prelude.Tracker.{Literal,Fun,Not,Transform,Type}

  @unsafe Prelude.Status.UNSAFE
  @safe Prelude.Status.SAFE

  def transform(%{typed_code: code} = module) do
    code = Enum.map(code, &function(&1, module))
    %{module | typed_code: code}
  end

  defp function(%{code: labels} = f, _) do
    code = labels
    |> Stream.map(fn({lbl, ops}) ->
      {lbl, Enum.map(ops, &map_op/1)}
    end)
    |> Enum.into(%{})

    %{f | code: code}
  end

  defp map_op(%{registers: registers, stack: stack, info: info} = op) do
    registers = resolve_type_set(registers)
    stack = resolve_type_set(stack)
    %{op | info: Map.put(info, :status, %{registers: registers, stack: stack})}
  end

  defp resolve_type_set(map) when is_map(map) do
    map
    |> Stream.map(fn({i, t}) ->
      {i, resolve_type(t)}
    end)
    |> Enum.into(%{})
  end

  defp resolve_type(%Literal{value: value}) do
    resolve_type(value)
  end
  defp resolve_type(%Transform{input: i}) do
    resolve_type(i)
  end
  defp resolve_type(%s{}) when s in [Fun,Type,Not] do
    @safe
  end
  defp resolve_type(%_{}) do
    @unsafe
  end
  defp resolve_type(_) do
    @safe
  end
end
