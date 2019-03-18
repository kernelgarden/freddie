defmodule Mix.Tasks.Freddie.Scaffold do
  use Mix.Task

  @elixir_version ">= 1.6"

  @impl true
  def run(args) do
    IO.puts("#{inspect args}")
    validate_elixir_version()
  end

  defp validate_elixir_version() do
    unless Version.match?(System.version, @elixir_version) do
      Mix.raise("Freddie require Elixir #{@elixir_version} version. You have #{System.version} now.")
    end
  end

end
