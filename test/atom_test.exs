defmodule Prelude.Test.Atom do
  use Prelude.Test.Case

  preludetest "static" do
    # def test(a) do
    #   case a do
    #     1 ->
    #       :integer
    #     [] ->
    #       :list
    #     %{} ->
    #       :map
    #   end
    # end

    def test() do
      a = bar(1)
      fun = fn(b, c) ->
        a + b + c
      end
      fun.(2, 3)
    end

    defp bar(a) do
      a
    end
  end
end
