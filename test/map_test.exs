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
end
