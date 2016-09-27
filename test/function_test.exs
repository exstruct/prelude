defmodule Test.Prelude.Function do
  use Test.Prelude.Case

  preludetest "local" do
    def test() do
      local(1)
    end

    defp local(v) do
      v
    end
  end

  preludetest "local pattern match" do
    def test() do
      {local(ok(1)), local(2)}
    end

    defp local(1) do
      "Hello"
    end
    defp local(_) do
      "Robert"
    end
  end

  preludetest "recursion" do
    def test() do
      local(ok(5))
    end

    defp local(0) do
      []
    end
    defp local(n) do
      [{:foo, n} | local(n - 1)]
    end
  end
end
