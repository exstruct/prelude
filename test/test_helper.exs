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
        dispatch = Etude.Dispatch.Fallback

        future = unquote(module).__etude__(:test, 0, dispatch)
        |> Etude.Future.ap([])
        |> Etude.Traversable.traverse()

        # Prelude.Test.Case.__time__(future, unquote(module))

        var!(value) = Etude.fork!(future)
        expected = unquote(module).test()

        assert var!(value) == expected

        unquote(case assertions do
          [after: assertions] ->
            assertions
          [] ->
            true
        end)
      end
    end
  end

  def __time__(future, module) do
    times = 1000
    {f, e} = Enum.reduce(1..times, {0, 0}, fn(_, {f_time, e_time}) ->
      {f, _value} = :timer.tc(Etude, :fork!, [future])
      {e, _expected} = :timer.tc(module, :test, [])
      {f_time + f, e_time + e}
    end)
    f = f/times
    e = e/times
    IO.inspect {module, f, e, times(f, e)}
  end

  defp times(t, 0.0) do
    t
  end
  defp times(f, e) do
    f / e
  end
end

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
