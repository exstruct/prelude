defmodule Prelude.Test.Mazurka do
  use Prelude.Test.Case

  preludetest "basic resource" do
    use Mazurka.Resource

    def test() do
      action([], %{"user" => "foo123"}, %{}, %{})
    end

    param user, fn(id) ->
      %{id: id,
        name: "Joe",
        age: 42}
    end

    mediatype Hyper do
      action do
        %{
          "name" => user.name,
          "age" => user.age
        }
      end
    end
  end
end
