defmodule Prelude.Test.Op do
  use Prelude.Test.Case

  preludetest "addition" do
    def test() do
      1 + 1
    end
  end

  preludetest "subtraction" do
    def test() do
      1 - 1
    end
  end

  preludetest "addition variable" do
    def test() do
      a = :erlang.hd([1])
      b = :erlang.hd([2])
      a + b
    end
  end
end
