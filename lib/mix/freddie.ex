defmodule Mix.Freddie do
  def watched_modules do
    watched_modules_list()
  end

  defp watched_modules_list do
    watched_modules_list = []

    watched_modules_list =
      case Application.get_env(:freddie, :scheme_root_mod, nil) do
        nil ->
          watched_modules_list

        root_mod ->
          if Code.ensure_compiled?(root_mod),
            do: [root_mod | watched_modules_list],
            else: watched_modules_list
      end

    watched_modules_list
  end
end
