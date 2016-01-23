defmodule Prelude.Test.Var do
  use Prelude.Test.Case

  preludetest "simple" do
    def test() do
      foo = "bar"
      foo
    end
  end

  preludetest "rebind" do
    def test() do
      i = 1
      i = i + 1
      i = i + 2
      i = i + 3
      i
    end
  end
end
