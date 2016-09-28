defmodule Prelude.Transform do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmodule Op do
    defstruct [op: nil,
               registers: %{},
               stack: %{},
               info: %{}]
  end

  defmacro defop({name, meta, args}) do
    t = {:{}, meta, [name | args]}
    quote do
      def op([unquote(t) = op | ops], acc, state) do
        _ = unquote(t)
        {ops, [op | acc], state}
      end
    end
  end
  defmacro defop(name) do
    quote do
      def op([unquote(name) = op | ops], acc, state) do
        {ops, [op | acc], state}
      end
    end
  end

  defmacro defop(arg, body) do
    ast = compile_op(arg, body)
#    ast |> Macro.to_string |> IO.puts
    ast
  end

  defp compile_op({:when, _, [{name, meta, args}, check]}, [do: body]) do
    t = {:{}, meta, [name | args]}
    quote do
      def op([%{op: unquote(t)} = var!(op) | var!(ops)], acc, var!(state)) when unquote(check) do
        _ = var!(op)
        _ = var!(state)
        state = unquote(body)
        {var!(ops), [var!(op) | acc], state}
      end
      def op([unquote(t) = var!(op) | var!(ops)], acc, var!(state)) when unquote(check) do
        _ = var!(op)
        _ = var!(state)
        state = unquote(body)
        {var!(ops), [var!(op) | acc], state}
      end
    end
  end
  defp compile_op({name, meta, args}, [do: body]) do
    t = {:{}, meta, [name | args]}
    quote do
      def op([%{op: unquote(t)} = var!(op) | var!(ops)], acc, var!(state)) do
        _ = var!(op)
        _ = var!(state)
        state = unquote(body)
        {var!(ops), [var!(op) | acc], state}
      end
      def op([unquote(t) = var!(op) | var!(ops)], acc, var!(state)) do
        _ = var!(op)
        state = unquote(body)
        {var!(ops), [var!(op) | acc], state}
      end
    end
  end

  def consume(ops, count \\ 1) do
    consume(ops, [], count)
  end

  defp consume(ops, acc, 0) do
    {:lists.reverse(acc), ops}
  end
  defp consume([op | ops], acc, count) when count >= 1 do
    consume(ops, [op | acc], count - 1)
  end
end
