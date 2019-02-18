defmodule Freddie.Router.Builder do
  def compile(module, schemes) do
    {:ok, ^module, binary} =
      module
      |> build_abstract(schemes)
      |> IO.inspect(label: "[DEBUG] => ")
      |> Enum.map(&:erl_syntax.revert/1)
      |> IO.inspect(label: "[DEBUG] => ")
      |> :compile.forms([:verbose, :report_errors])

    binary
  end

  def key_to_term(key) do
    name =
      key
      |> Module.split()
      |> Enum.join("_")
      |> String.downcase()

    :"#{name}"
  end

  defp value_to_export_abstract(key) do
    key_term = key_to_term(key)

    import :erl_syntax

    [
      # -export([value/0]).
      attribute(
        atom(:export),
        [list([arity_qualifier(atom(key_term), integer(0))])]
      )
    ]
  end

  defp value_to_definition_abstract(key, value) do
    key_term = key_to_term(key)

    import :erl_syntax

    [
      # value() -> value.
      function(
        atom(key_term),
        [clause([], :none, [abstract(value)])]
      )
    ]
  end

  defp build_abstract(module, scheme_list) do
    import :erl_syntax

    syntax_tree = [
      # -module(module).
      attribute(
        atom(:module),
        [atom(module)]
      )
    ]

    exports_tree =
      scheme_list
      |> Enum.reduce([], fn {scheme, _idx}, acc ->
        value_to_export_abstract(scheme) ++ acc
      end)

    definitions_tree =
      scheme_list
      |> Enum.reduce([], fn {scheme, idx}, acc ->
        value_to_definition_abstract(scheme, idx) ++ acc
      end)

    syntax_tree ++ exports_tree ++ definitions_tree
  end
end
