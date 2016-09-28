defmodule Test.Prelude.Atom do
  use Test.Prelude.Case

  preludetest "static" do
    def test() do
      a = nil
      a
    end
  end

  preludetest "construct" do
    def test() do
      a = 123
      :"#{a}"
    end
  end

  preludetest "ok construct" do
    def test() do
      a = ok(123)
      :"#{a}"
    end
  end
end
