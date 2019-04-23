defmodule Mix.Freddie do
  @moduledoc false

  def watched_modules do
    watched_modules_list()
  end

  defp watched_modules_list do
    watched_modules_list =
      [:scheme_root_mod, :packet_type_mod, :packet_handler_mod]
      |> Stream.map(&check_load/1)
      |> Stream.filter(&(&1 != nil))
      |> Enum.into([])

    watched_modules_list
  end

  defp check_load(mod) do
    case Application.get_env(:freddie, mod, nil) do
        nil ->
          nil

        root_mod ->
          if Code.ensure_loaded?(root_mod),
            do: root_mod,
            else: nil
      end
  end
end
