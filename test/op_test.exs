defmodule Test.Prelude.Op do
  use Test.Prelude.Case

  preludetest "addition" do
    def test() do
      ok(1) + 1
    end
  end

  preludetest "subtraction" do
    def test() do
      ok(1) - 1
    end
  end

  preludetest "addition variable" do
    def test() do
      a = ok(1)
      b = ok(2)
      a + b
    end
  end
end
