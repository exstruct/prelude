defmodule Prelude.Test.Compiler do
  use Prelude.Test.Case

  @tag :pending
  preludetest "users" do
    def test() do
      __MODULE__.read(%{}, 2)
    end

    def read(conn, id) when is_integer(id) do
      read(conn, to_string(id))
    end
    def read(_conn, id) do
      user = Users.read(id)
      hello(user)
    end

    defp hello(%{name: name}) do
      "Hello, " <> name
    end
  end
end
