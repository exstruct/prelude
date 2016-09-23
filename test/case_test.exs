defmodule Prelude.Test.CaseExpr do
  use Prelude.Test.Case

  preludetest "variable" do
    def test() do
      value = true
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

  preludetest "lazy case" do
    def test do
      value = :erlang.hd([1])
      case :erlang.hd([{{{{{value}}}}}]) do
        {{{{{v}}}}} when is_integer(v) ->
          v
      end
    end
  end

  preludetest "elixir shadow" do
    def test do
      check(:ok, true, 1, 2, 3)
    end

    defp check(a,b,c,d,e) do
      case :erlang.hd([a,b,c,d,e]) do
        :ok ->
          if :erlang.hd([b,c,d,e]) do
            :ok
          else
            :error
          end
        other ->
          other
      end
    end
  end
end
