defmodule Prelude.Test.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: false
      import Prelude
      import unquote(__MODULE__)
    end
  end

  defmacro preludetest(name, [{:do, body} | assertions]) do
    module = Module.concat(__CALLER__.module, name |> String.replace(" ", "_") |> Mix.Utils.camelize())
    quote do
      unquote({:defmodule, [], [module, [do: [{:use, [], [Prelude]}, body]]]})

      test unquote(name) do
        #var!(value) = unquote(module).test()
        #_ = var!(value)

        unquote(case assertions do
          [after: assertions] ->
            assertions
          [] ->
            true
        end)
      end
    end
  end

  def hello(name) do
    Etude.ok(%{hello: name})
  end
end

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
