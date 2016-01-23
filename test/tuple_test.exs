defmodule Prelude.Test.Tuple do
  use Prelude.Test.Case

  preludetest "empty" do
    def test() do
      {}
    end
  end

  preludetest "static" do
    def test() do
      {1,2,3,4}
    end
  end

  preludetest "static match" do
    def test() do
      {_,_,_,a} = {"one","two","three","four"}
      a
    end
  end
end
