defmodule Prelude.Type do
  defstruct [:type]

  types = [
    :atom,
    :binary,
    :bitstring,
    :boolean,
    :float,
    :function,
    :integer,
    :list,
    :map,
    :nil,
    :nonempty_list,
    :number,
    :pid,
    :port,
    :reference,
    :tuple
  ]

  for type <- types do
    def unquote(type)() do
      %__MODULE__{type: unquote(type)}
    end

    def from_test(unquote(:"is_#{type}")) do
      %__MODULE__{type: unquote(type)}
    end
  end

  defmodule Argument do
    defstruct [:function, :arity, :pos]
  end

  defmodule Arithmetic do
    defstruct [:op, :left, :right]
  end

  defmodule FArithmetic do
    defstruct [:op, :left, :right]
  end

  defmodule Arity do
    defstruct [:arity]
  end

  defmodule ExtCall do
    defstruct [:module, :function, :arity, :arguments]
  end

  defmodule LocalCall do
    defstruct [:function, :arity, :arguments]
  end

  defmodule BIF do
    defstruct [:name, :arguments]
  end

  defmodule Not do
    defstruct [:type]
  end

  defmodule And do
    defstruct [:left, :right]
  end

  defmodule Or do
    defstruct [:left, :right]
  end

  defmodule LT do
    defstruct [:left, :right]
  end

  defmodule GE do
    defstruct [:left, :right]
  end

  defmodule EQ do
    defstruct [:left, :right]
  end

  defmodule NE do
    defstruct [:left, :right]
  end

  defmodule EQExact do
    defstruct [:left, :right]
  end

  defmodule NEExact do
    defstruct [:left, :right]
  end

  defmodule Fun do
    defstruct [:fun, :arity, :env]
  end

  defmodule Literal do
    defstruct [:value]
  end

  defmodule Binary do
    defstruct [:fields]
  end

  defmodule BinaryField do
    defstruct [:value, :size, :type, :flags]
  end

  defmodule Cons do
    defstruct [:head, :tail]
  end

  defmodule Head do
    defstruct [:cons]
  end

  defmodule Tail do
    defstruct [:cons]
  end

  defmodule Tuple do
    defstruct [:elements]
  end

  defmodule TupleElement do
    defstruct [:tuple, :idx]
  end

  defmodule Map do
    defstruct [:fields]
  end

  defmodule MapField do
    defstruct [:key, :term]
  end

  defmodule MapElement do
    defstruct [:map, :key]
  end

  defmodule Message do
    defstruct []
  end

  defmodule Exception do
    defstruct [:class, :type]
  end
end
