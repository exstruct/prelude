defmodule Test.Prelude.CaseExpr do
  use Test.Prelude.Case

  preludetest "variable" do
    def test() do
      value = ok(true)
      case value do
        true ->
          greeting = "Hello"
          greeting
        _ ->
          "Goodbye"
      end
    end
  end

  preludetest "if/else" do
    def test() do
      value = ok(true)
      if value do
        "truthy"
      else
        "falsy"
      end
    end
  end

  preludetest "not" do
    def test() do
      value = is_atom(ok(:foo))
      !value
    end
  end

  preludetest "local scope" do
    def test() do
      value = ok(true)
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
      var = ok("Hello")
      value = ok(true)
      case value do
        true when var == "Hello" ->
          var <> ", Joe"
        _ ->
          "Robert"
      end
    end
  end

  preludetest "lazy case" do
    def test do
      value = ok(1)
      case :erlang.hd([{{{{{value}}}}}]) do
        {{{{{v}}}}} when is_integer(v) ->
          v
      end
    end
  end
end
