defmodule Prelude.Test.Comprehension do
  use Prelude.Test.Case

  preludetest "range" do
    def test() do
      for x <- 1..3 do
        x * x
      end
    end
  end

  preludetest "double" do
    def test() do
      for x <- 1..3, y <- 1..3 do
        {x, y}
      end
    end
  end
end
