defmodule Mix.Tasks.Freddie.Routes do
  use Mix.Task

  @impl true
  def run(args) do
    args
    |> Enum.at(0, :none)

    IO.puts("Hello, World! - #{args}")
  end
end
