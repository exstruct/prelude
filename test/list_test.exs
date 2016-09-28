defmodule Test.Prelude.List do
  use Test.Prelude.Case

  # preludetest "empty" do
  #   def test() do
  #     []
  #   end
  # end

  # preludetest "static" do
  #   def test() do
  #     [1,2,3]
  #   end
  # end

  # preludetest "ok items" do
  #   def test() do
  #     [ok(1), ok(2), ok(3)]
  #   end
  # end

  # preludetest "ok cons" do
  #   def test() do
  #     [ok(1) | ok([2, 3])]
  #   end
  # end

  preludetest "ok cons pattern match" do
    def test() do
      [hd | _] = ok([1,2,3])
      hd
    end
  end
end
