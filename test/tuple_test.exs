defmodule Test.Prelude.Tuple do
  use Test.Prelude.Case

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

  preludetest "ok tuple" do
    def test() do
      ok({1,2,3})
    end
  end

  preludetest "ok tuple match" do
    def test() do
      {a,b,c} = ok({1,2,3})
      {c,b,a}
    end
  end
end
