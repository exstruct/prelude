defmodule Prelude.Etude.Node.Match do
  use Prelude.Etude.Node

  def exit({:match, line, lhs, rhs_w}, state) do
    rhs = unwrap(rhs_w)
    if ready?(rhs_w, state) do
      {optimize(line, lhs, rhs), state}
    else
      case lhs do
        {:var, _, _} ->
          {optimize(line, lhs, rhs), state}
        _ ->
          case postwalk(lhs, state) do
            {_, []} ->
              ## TODO handle case when there are no variables
              {optimize(line, lhs, rhs), state}
            {lhs, vars} ->
              vars = Enum.reverse(vars)
              assign = {:tuple, line, Enum.map(vars, fn({var, _}) -> var end)}
              match = {:tuple, line, Enum.map(vars, fn({_, var}) -> var end)}
              match_var = var_for_node(rhs)
              returns = {:tuple, line, return_values(line, match_var, vars)}

              node = ~S"""
              unquote(assign) = begin
                unquote(match_var) = #{'__struct__' => 'Elixir.Prelude.Etude.Node.Match.Thunk',
                                      expression => unquote(rhs),
                                      match => fun
                                        (unquote(lhs)) ->
                                          unquote(match)
                                        % TODO figure out stacktrace
                                        %;
                                        %(__etude_match_term) ->
                                        %  erlang:raise(
                                        %    error,
                                        %    'Elixir.MatchError':exception([{term, __etude_match_term}]),
                                        %    'Elixir.System':stacktrace()
                                        %  )
                                      end},
                unquote(returns)
              end
              """
              |> erl(line)

              {node, state}
          end
      end
    end
  end

  defp optimize(line, node, node) do
    {:atom, line, nil}
  end
  defp optimize(line, lhs, rhs) do
    {:match, line, lhs, rhs}
  end

  defp postwalk(lhs, _state) do
    Prelude.ErlSyntax.postwalk(lhs, [], fn
      ({:var, _, _} = var, acc) ->
        etude_var = var_for_node(var)
        {etude_var, [{var, etude_var} | acc]}
      (node, acc) ->
        {node, acc}
    end)
  end

  defp return_values(line, var, vars) do
    vars
    |> Stream.with_index()
    |> Enum.map(fn({_, i}) ->
      i = escape(i + 1)
      ~S"""
      #{'__struct__' => 'Elixir.Prelude.Etude.Node.MatchVar.Thunk',
        match => unquote(var),
        index => unquote(i)}
      """
      |> erl(line)
    end)
  end
end

defmodule Prelude.Etude.Node.Match.Thunk do
  defstruct expression: nil,
            match: nil
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.Match.Thunk do
  def resolve(%{expression: expression, match: match}, state) do
    ## TODO make this not as eager... maybe it's not possible without
    ##      reimplementing the BEAM pattern matching
    Etude.Thunk.resolve_recursive(expression, state, fn(expression, state) ->
      {match.(expression), state}
    end)
  end
end

defmodule Prelude.Etude.Node.MatchVar.Thunk do
  defstruct match: nil,
            index: 0
end

defimpl Etude.Thunk, for: Prelude.Etude.Node.MatchVar.Thunk do
  def resolve(%{match: match, index: index}, state) do
    Etude.Thunk.resolve(match, state, fn(value, state) ->
      {:erlang.element(index, value), state}
    end)
  end
end
