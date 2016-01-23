defmodule Prelude.Etude.Var do
  import Prelude.Etude.Utils
  import Prelude.ErlSyntax

  def exit(node, acc) do
    if in_scope?(node, acc.scopes) do
      {ready(node, -1), acc}
    else
      {~e[(unquote(node))()], acc}
    end
  end
end
