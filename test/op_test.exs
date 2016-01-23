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
end
