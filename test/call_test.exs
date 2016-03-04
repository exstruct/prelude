defmodule Prelude.Test.Call do
  use Prelude.Test.Case

  preludetest "static call" do
    def test() do
      :erlang.hd([1])
    end
  end

  preludetest "nested call" do
    def test() do
      :erlang.hd([
        :erlang.hd([1]),
        :erlang.hd([2]),
        :erlang.hd([3])
      ])
    end
  end

  preludetest "dynamic call" do
    def test() do
      module = String.to_atom("erlang")
      module.hd([1])
    end
  end
end
