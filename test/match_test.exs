defmodule Prelude.Test.Match do
  use Prelude.Test.Case

  preludetest "single nested" do
    def test() do
      {{{foo}}} = :erlang.hd([{{{1}}}])
      foo
    end
  end

  preludetest "multi nested" do
    def test() do
      {a, {b, {c, {d, {e}}}}} = :erlang.hd([{1, {2, {3, {4, {5}}}}}])
      {a,b,c,d,e}
    end
  end
end
