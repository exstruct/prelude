defmodule Test.Prelude.Match do
  use Test.Prelude.Case

  preludetest "single nested" do
    def test() do
      {{{foo}}} = ok({{{1}}})
      foo
    end
  end

  preludetest "multi nested" do
    def test() do
      {a, {b, {c, {d, {e}}}}} = ok({1, ok({2, {3, ok({4, {5}})}})})
      {a,b,c,d,e}
    end
  end
end
