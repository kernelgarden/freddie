defmodule Mix.Tasks.Freddie.Server do
  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("loadpaths")

    case args do
      ["start"] ->
        start()

      _ ->
        IO.puts("Wrong!")
    end
  end

  def start do
    {:ok, _} = Application.ensure_all_started(:freddie)

    renew()

    Mix.Tasks.Run.run(run_args())
  end

  def renew do
    Mix.Freddie.watched_modules
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

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
