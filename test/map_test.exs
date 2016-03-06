defmodule Prelude.Test.Map do
  use Prelude.Test.Case

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
      key = :erlang.hd(["foo"])
      %{key => "bar"}
    end
  end

  preludetest "update variable map" do
    def test() do
      map = :erlang.hd([%{"hello" => "Robert"}])
      %{map | "hello" => "Mike"}
    end
  end

  preludetest "update variable map with variable keys" do
    def test() do
      map = :erlang.hd([%{"foo" => "bar"}])
      key = :erlang.hd(["foo"])
      %{map | key => "baz"}
    end
  end
end
