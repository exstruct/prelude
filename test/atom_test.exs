defmodule Prelude.Test.Atom do
  use Prelude.Test.Case

  preludetest "static" do
    def test() do
      :hello
    end
  end

  preludetest "interpolate" do
    def test() do
      name = "Joe"
      :"hello, #{name}"
    end
  end
end
