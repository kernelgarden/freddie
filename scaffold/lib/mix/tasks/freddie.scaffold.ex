defmodule Mix.Tasks.Freddie.Scaffold do
  use Mix.Task

  alias FreddieScaffold.{Generator, Firewood}

  @elixir_version ">= 1.6.0"

  @impl true
  @shortdoc "Create a new freddie server application."
  def run(args) do
    validate_elixir_version()

    case args do
      [app_name | _] ->
        {:ok, executed_path} = File.cwd()

        # now, we have only a normal_app
        firewood = Firewood.NormalApp

        {executed_path, app_name, firewood}
        |> FreddieScaffold.ProjectInfo.new()
        |> Generator.generate()

        print_success_msg(app_name)

      _ ->
        Mix.raise("Invalid intput!\nPlease type: mix freddie.scaffold [app_name]")
    end
  end

  defp validate_elixir_version() do
    unless Version.match?(System.version(), @elixir_version) do
      Mix.raise(
        "Freddie require Elixir #{@elixir_version} version. You have #{System.version()} now."
      )
    end
  end

  defp print_success_msg(app_name) do
    IO.puts("\nCreate #{app_name} successfully!")
  end
end
