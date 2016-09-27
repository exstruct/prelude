defmodule Test.Prelude.Call do
  use Test.Prelude.Case

  preludetest "static" do
    def test() do
      ok(123)
    end
  end

  preludetest "nested" do
    def test() do
      ok([
        ok(1),
        ok(2),
        ok(3)
      ])
    end
  end

  preludetest "dynamic" do
    def test() do
      module = ok(:erlang)
      module.hd([1])
    end
  end
end
