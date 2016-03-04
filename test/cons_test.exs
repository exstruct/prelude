defmodule Prelude.Test.Cons do
  use Prelude.Test.Case

  # preludetest "empty" do
  #   def test() do
  #     []
  #   end
  # end

  # preludetest "static" do
  #   def test() do
  #     [1,2,3,4]
  #   end
  # end

  preludetest "variable" do
    def test() do
      foo = [3]
      bar = [2 | foo]
      [1 | bar]
    end
  end

  # preludetest "match" do
  #   def test() do
  #     [1,2,3,prop|_] = [1,2,3,4,5,6,7]
  #     prop
  #   end
  # end

  # preludetest "mutiple match" do
  #   def test() do
  #     [1,2,prop1,prop2|_] = [1,2,3,4,5,6,7]
  #     [prop1, prop2]
  #   end
  # end
end
