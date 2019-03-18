defmodule Mix.Tasks.Freddie.Scaffold do
  use Mix.Task

  alias FreddieScaffold.Generator

  @elixir_version ">= 1.6.0"

  @impl true
  def run(args) do
    IO.puts("#{inspect args}")
    validate_elixir_version()

    case args do
      [app_name | _] ->
        {:ok, executed_path} = File.cwd()

        {executed_path, app_name}
        |> Generator.generate()

      _ -> Mix.raise("Invalid intput!\nPlease type: mix freddie.scaffold [app_name]")
    end
  end

  defp validate_elixir_version() do
    unless Version.match?(System.version, @elixir_version) do
      Mix.raise("Freddie require Elixir #{@elixir_version} version. You have #{System.version} now.")
    end
  end

end
