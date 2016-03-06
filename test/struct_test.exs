defmodule Prelude.Test.Struct do
  use Prelude.Test.Case

  preludetest "struct" do
    defstruct foo: nil

    def test() do
      s = %__MODULE__{foo: 1}
      s.foo
    end
  end
end
