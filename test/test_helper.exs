defmodule Prelude.Test.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      import Prelude
      import unquote(__MODULE__)
    end
  end

  defmacro preludetest(name, [body | assertions]) do
    base = Module.concat(__CALLER__.module, name |> String.replace(" ", "_") |> Mix.Utils.camelize())
    actual = Module.concat(base, "Actual")
    expected = Module.concat(base, "Expected")
    quote do
      unquote({:defmodule, [], [expected, [body]]})

      test unquote(name) do
        {:ok, mod, bin} = defetude unquote(actual), unquote([body])
        :code.load_binary(mod, __ENV__.file |> to_char_list(), bin)

        dispatch = Etude.Dispatch.Fallback
        state = %Etude.State{mailbox: self()}

        {var!(value), _} = mod.__etude__(:test, 0, dispatch)
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
