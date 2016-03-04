defmodule Prelude.Test.CaseExpr do
  use Prelude.Test.Case

  preludetest "variable" do
    def test() do
      value = true
      case value do
        true ->
          "Hello"
        _ ->
          "Goodbye"
      end
    end
  end

  preludetest "if/else" do
    def test() do
      value = true
      if value do
        "truthy"
      else
        "falsy"
      end
    end
  end

  preludetest "not" do
    def test() do
      value = is_atom(:foo)
      !value
    end
  end

  preludetest "local scope" do
    def test() do
      value = true
      case {value, "Mike"} do
        {true, name} ->
          "Hello, " <> name
        _ ->
          "Hello, Joe"
      end
    end
  end

  preludetest "when" do
    def test() do
      var = "Hello"
      value = true
      case value do
        true when var == "Hello" ->
          var <> ", Joe"
        _ ->
          "Robert"
      end
    end
  end
end
