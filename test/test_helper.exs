defmodule Test.Prelude.Case do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: Mix.env == :test
      import Prelude
      import unquote(__MODULE__)
    end
  end

  defmacro preludetest(name, [{:do, body} | assertions]) do
    base = Module.concat(__CALLER__.module, name |> String.replace(" ", "_") |> Mix.Utils.camelize())
    control = Module.concat(base, CONTROL)
    subject = Module.concat(base, SUBJECT)
    quote do
      unquote({:defmodule, [], [control, [do: body]]})
      unquote({:defmodule, [], [subject, [do: [{:use, [], [Prelude]}, body]]]})

      test unquote(name) do
        control = unquote(__MODULE__).__execute__(unquote(control), false)
        subject_normal = unquote(__MODULE__).__execute__(unquote(subject).__etude__, false)
        subject = unquote(__MODULE__).__execute__(unquote(subject).__etude__, true)

        assert control == subject_normal
        assert control == subject

        var!(value) = subject
        _ = var!(value)

        unquote(case assertions do
          [after: assertions] ->
            assertions
          [] ->
            true
        end)
      end
    end
  end

  def ok(v) do
    if future?() do
      Etude.ok(v)
    else
      v
    end
  end

  def error(name) do
    if future?() do
      Etude.wrap(fn ->
        throw name
      end)
    else
      throw name
    end
  end

  defp future?() do
    Process.get(__MODULE__)
  end

  def __execute__(module, future) do
    Process.put(__MODULE__, future)
    try do
      if future do
        module.test()
        |> Etude.Traversable.traverse()
        |> Etude.fork!()
      else
        module.test()
      end
    rescue
      e ->
        e
    catch
      :throw, e ->
        {__MODULE__.THROW, e}
    after
      Process.delete(__MODULE__)
    end
  end
end

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
