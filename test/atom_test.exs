defmodule Prelude.Test.Atom do
  use Prelude.Test.Case

  preludetest "static" do
    def test() do
      # %Etude.Chain{
      #   future: hello("joe"),
      #   on_ok: fn(%{name: name}) ->
      #     name
      #   end
      # }
      %{name: name} = hello("joe")
      name
    end
  end
end
