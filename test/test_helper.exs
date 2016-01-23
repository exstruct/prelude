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
      test unquote(name) do
        defmodule unquote(expected), unquote([body])

        {:ok, mod, bin} = defetude unquote(actual), unquote([body])
        :code.load_binary(mod, __ENV__.file |> to_char_list(), bin)

        ## TODO remove this once we get more done
        {:__ETUDE_READY__, var!(value)} = mod.test()

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
