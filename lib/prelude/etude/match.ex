defmodule Prelude.Etude.Match do
  import Prelude.ErlSyntax
  import Prelude.Etude.Utils

  def exit({:match, _, {:var, _, _} = lhs, rhs}) do
    ~e"""
    unquote(lhs) = fun() ->
      unquote(rhs)
    end
    """
  end
  def exit({:match, line, lhs, rhs}) do
    lhs
    |> extract_vars()
    |> compile_match(line, lhs, rhs)
  end

  defp compile_match([var], line, lhs, ready(rhs)) do
    match_var = ready(var, line)
    ~e"""
    unquote(var) = fun() ->
      unquote(lhs) = unquote(rhs),
      unquote(match_var)
    end
    """
  end
  defp compile_match([var], line, lhs, rhs) do
    match_var = ready(var, line)
    lhs_match = ready(lhs, line)
    ~e"""
    unquote(var) = fun() ->
      case unquote(rhs) of
        unquote(lhs_match) ->
          unquote(match_var);
        unquote(pending) ->
          unquote(pending)
      end
    end
    """
  end
  defp compile_match(vars, line, lhs, rhs) do
    var = var_for_node({:match, line, lhs, rhs})

    var_funs = compile_vars(var, vars, rhs)

    match_vars = {:tuple, line, vars}
    main = compile_main(var, lhs, rhs, match_vars)

    ~e"""
    unquote(match_vars) = begin
      unquote(main),
      unquote(var_funs)
    end
    """
  end

  defp compile_vars(main, vars, ready(_)) do
    {:tuple, -1, Enum.map(vars, fn(v) ->
      line = elem(v, 1)
      match = {:tuple, line, match_var(v, vars)}
      v = ready(v, line)
      ~e"""
      fun() ->
        unquote(match) = (unquote(main))(),
        unquote(v)
      end
      """
    end)}
  end
  defp compile_vars(main, vars, _) do
    {:tuple, -1, Enum.map(vars, fn(v) ->
      line = elem(v, 1)
      match = ready({:tuple, line, match_var(v, vars)}, line)
      v = ready(v, line)
      ~e"""
      fun() ->
        case (unquote(main))() of
          unquote(match) ->
            unquote(v);
          unquote(pending) ->
            unquote(pending)
        end
      end
      """
    end)}
  end

  defp compile_main(var, lhs, ready(rhs), match_vars) do
    ~e"""
    unquote(var) = fun() ->
      unquote(lhs) = unquote(rhs),
      unquote(match_vars)
    end
    """
  end
  defp compile_main(var, lhs, rhs, match_vars) do
    line = elem(lhs, 1)
    match_vars = ready(match_vars, line)
    ready_lhs = ready(lhs, line)
    ~e"""
    unquote(var) = fun() ->
      case unquote(rhs) of
        unquote(ready_lhs) ->
          unquote(match_vars);
        unquote(pending) ->
          unquote(pending)
      end
    end
    """
  end

  defp match_var(name, vars) do
    Enum.map(vars, fn
      (n) when n == name ->
        name
      (_) ->
        {:var, -1, :_}
    end)
  end
end
