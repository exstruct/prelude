defmodule Prelude.Test.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      import Prelude
      import unquote(__MODULE__)
    end
  end

  defmacro preludetest(name, [{:do, body} | assertions]) do
    module = Module.concat(__CALLER__.module, name |> String.replace(" ", "_") |> Mix.Utils.camelize())
    quote do
      unquote({:defmodule, [], [module, [do: [{:use, [], [Prelude]}, body]]]})

      test unquote(name) do
        dispatch = Etude.Dispatch.Fallback
        state = %Etude.State{mailbox: self()}

        {var!(value), state} = unquote(module).__etude__(:test, 0, dispatch)
        |> Etude.resolve(state)

        assert var!(value) == unquote(module).test()

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
