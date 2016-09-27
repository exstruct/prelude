defmodule Test.Prelude.Mazurka do
  use Test.Prelude.Case

  preludetest "basic resource" do
    use Mazurka.Resource

    def test() do
      action([], %{"user" => ok("foo123")}, %{}, %{})
    end

    param user, fn(id) ->
      %{id: id,
        name: ok("Joe"),
        age: ok(42)} |> ok()
    end

    condition ok(user.age > 40)

    mediatype Hyper do
      action do
        %{
          "name" => user.name,
          "age" => user.age
        } |> ok()
      end
    end
  end
end
