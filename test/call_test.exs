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

  preludetest "dynamic apply" do
    def test() do
      module = ok(Enum)
      module.concat([1], [2])
      |> ok()
    end
  end

  preludetest "dynamic apply last" do
    def test() do
      module = ok(Enum)
      module.concat([1], [2])
    end
  end

  preludetest "unused return value" do
    def test() do
      error("Joe")

      ok("Robert")
    end
  end
end
