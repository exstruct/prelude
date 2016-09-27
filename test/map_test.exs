defmodule Test.Prelude.Map do
  use Test.Prelude.Case

  preludetest "empty" do
    def test() do
      %{}
    end
  end

  preludetest "static property" do
    def test() do
      %{"hello" => "world"}
    end
  end

  preludetest "update property" do
    def test() do
      map = %{"hello" => "world"}
      %{map | "hello" => "Joe"}
    end
  end

  preludetest "variable keys" do
    def test() do
      key = ok("foo")
      %{key => "bar"}
    end
  end

  preludetest "update variable map" do
    def test() do
      map = ok(%{"hello" => "Robert"})
      %{map | "hello" => "Mike"}
    end
  end

  preludetest "update variable map with variable keys" do
    def test() do
      map = ok(%{"foo" => "bar"})
      key = ok("foo")
      %{map | key => "baz"}
    end
  end
end
