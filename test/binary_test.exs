defmodule Prelude.Test.Binary do
  use Prelude.Test.Case

  preludetest "static" do
    def test() do
      "hello!"
    end
  end

  preludetest "static concat" do
    def test() do
      "hello, " <> "world!"
    end
  end

  preludetest "variable concat" do
    def test() do
      subject = "Joe"
      "hello, " <> subject
    end
  end

  preludetest "construction" do
    def test() do
      size = 32
      <<"h", 1 :: integer-little-size(size)>>
    end
  end
end
