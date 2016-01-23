defmodule Prelude.Etude.Function do
  import Prelude.Etude.Utils

  def exit({:function, line, name, arity, clauses}, acc) do
    {
      entry(name, arity),
      etude_clause(name, arity, clauses)
    }
  end

  defp entry(name, arity) do
    {args, cons} = args(arity)
    {:function, -1, name, arity,
      [{:clause, -1, args, [],
        [{:call, -1, {:remote, -1, {:atom, -1, Etude.Thunk}, {:atom, -1, :resolve}},
          [{:map, -1,
            [{:map_field_assoc, -1, {:atom, -1, :__struct__},
              {:atom, -1, Etude.Thunk.Continuation}},
             {:map_field_assoc, -1, {:atom, -1, :function},
              {:call, -1, {:atom, -1, :__etude__},
               [{:atom, -1, name}, {:integer, -1, arity},
                {:call, -1,
                 {:remote, -1, {:atom, -1, Etude.Dispatch},
                  {:atom, -1, :from_process}}, []}]}},
             {:map_field_assoc, -1, {:atom, -1, :arguments}, cons}]}]}]}]}
  end

  defp etude_clause(name, arity, clauses) do
    {:clause, -1, [{:atom, -1, name}, {:integer, -1, arity}, {:var, -1, :__Dispatch}], [], [
      {:named_fun, -1, :_Exec, clauses}]}
  end

  defp args(0) do
    {[], {nil, -1}}
  end
  defp args(arity) do
    {a, c} = args(arity - 1)
    var = {:var, -1, :"arg_#{arity}"}
    {[var | a], {:cons, -1, var, c}}
  end
end

    # {:named_fun, 2, :_Exec,
    #   [{:clause, 2, [{:var, 2, :S}, {:var, 2, :User}], [],
    #     [{:call, 3, {:remote, 3, {:atom, 3, Etude.Thunk}, {:atom, 3, :reduce}},
    #       [{:cons, 3, {:var, 3, :User}, {nil, 3}}, {:var, 3, :S},
    #        {:fun, 3,
    #         {:clauses,
    #          [{:clause, 4,
    #            [{:var, 4, :S1},
    #             {:map, 4,
    #              [{:map_field_exact, 4, {:atom, 4, :name}, {:var, 4, :Name}}]}],
    #            [],
    #            [{:call, 5,
    #              {:remote, 5, {:atom, 5, Etude.Thunk}, {:atom, 5, :reduce}},
    #              [{:cons, 5, {:var, 5, :Name}, {nil, 5}}, {:var, 5, :S1},
    #               {:fun, 5,
    #                {:clauses,
    #                 [{:clause, 5, [{:var, 5, :S2}, {:var, 5, :Name_}], [],
    #                   [{:tuple, 6,
    #                     [{:atom, 6, :ok},
    #                      {:bin, 6,
    #                       [{:bin_element, 6, {:string, ...}, :default, ...},
    #                        {:bin_element, 6, {:var, ...}, :default, ...}]},
    #                      {:var, 6, :S2}]}]}]}}]}]}]}}]}]}]}
