defmodule Prelude.Test.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      import Prelude
      import unquote(__MODULE__)
    end
  end

  defmacro preludetest(name, [{:do, body} | assertions]) do
    base = Module.concat(__CALLER__.module, name |> String.replace(" ", "_") |> Mix.Utils.camelize())
    actual = Module.concat(base, "Actual")
    expected = Module.concat(base, "Expected")
    quote do
      unquote({:defmodule, [], [expected, [do: body]]})

      unquote({:defmodule, [], [actual, [do: [{:use, [], [Prelude]}, body]]]})

      test unquote(name) do
        dispatch = Etude.Dispatch.Fallback
        state = %Etude.State{mailbox: self()}

        {var!(value), _} = unquote(actual).__etude__(:test, 0, dispatch)
        |> Etude.resolve(state)

        assert var!(value) == unquote(expected).test()

        unquote(case assertions do
          [after: assertions] ->
            assertions
          [] ->
            true
        end)
      end
    end
  end
end

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
