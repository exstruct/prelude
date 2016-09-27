defmodule Test.Prelude.Struct do
  use Test.Prelude.Case

  preludetest "struct" do
    defstruct foo: nil

    def test() do
      s = ok(%__MODULE__{foo: 1})
      s.foo
    end
  end
end
