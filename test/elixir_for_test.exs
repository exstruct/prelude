defmodule Test.Prelude.ElixirFor do
  use Test.Prelude.Case

  preludetest "range" do
    def test() do
      range = ok(1..3)
      for x <- range do
        x * x
      end
    end
  end

  preludetest "double" do
    def test() do
      first = ok(1..3)
      second = ok(1..3)
      for x <- first, y <- second do
        {x, y}
      end
    end
  end
end
