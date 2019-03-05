defmodule Mix.Tasks.Freddie.Server do
  use Mix.Task

  @impl true
  @shortdoc "Starts current freddie server application."
  def run(args) do
    case args do
      ["start"] ->
        start()

      _ ->
        print_guide()
    end
  end

  def start do
    run_by_enviroment()
    renew()
  end

  def renew do
    Mix.Freddie.watched_modules()
    |> modules_to_file_path()
    |> Stream.map(&renew_if_exists(&1))
    |> Stream.filter(&(&1 == :ok))
    |> Enum.to_list()
  end

  defp modules_to_file_path(modules) do
    Stream.map(modules, fn mod -> mod.__info__(:compile)[:source] end)
  end

  defp renew_if_exists(module_path) do
    :file.change_time(module_path, :calendar.local_time())
  end

  defp run_by_enviroment() do
    case iex_running?() do
      true ->
        Mix.Tasks.App.Start.run([])
      false ->
        Mix.Tasks.Run.run(["--no-halt"])
    end
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end

  defp print_guide do
    Mix.shell().info(
      ~S("iex --erl "+spp true" -S mix freddie.server start" or mix freddie.server start)
    )
  end
end
