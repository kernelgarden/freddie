defmodule Freddie.Utils.Eprof do
  use GenServer

  require Logger

  defstruct is_active: false, file_path: ""

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start(target) do
    GenServer.cast(__MODULE__, {:start, target})
  end

  def stop() do
    GenServer.cast(__MODULE__, {:stop})
  end

  def kill() do
    GenServer.cast(__MODULE__, {:kill})
  end

  @impl true
  @spec init(keyword()) :: {:ok, Freddie.Utils.Eprof.t()}
  def init(args) do
    Logger.info("Activate eprof server")
    file_path = Keyword.get(args, :path, "eprof.analysis")
    {:ok, %Freddie.Utils.Eprof{is_active: false, file_path: file_path}}
  end

  @impl true
  def handle_cast({:start, target}, state) do
    case state.is_active do
      false ->
        Logger.info("Start profiling with eprof")
        case :eprof.start_profiling([Process.whereis(target)]) do
          :profiling ->
            {:noreply, %Freddie.Utils.Eprof{state | is_active: true}}
          {:error, reason} ->
            Logger.error("Error occured from :eprof.start_profiling/1 - #{reason}")
        end
      true ->
        Logger.warn("Already started eprof!!!")
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:stop}, state) do
    case stop_profiling(state) do
      :ok ->
        {:noreply, %Freddie.Utils.Eprof{state | is_active: false}}
      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:kill}, state) do
    Logger.info("Terminate eprof server")
    if state.is_active, do: stop_profiling(state)

    {:stop, :normal, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warn("Received unknown msg!!! - #{inspect msg}")
    {:noreply, state}
  end

  defp stop_profiling(state) do
    case state.is_active do
      true ->
        Logger.info("Stop profiing")
        :eprof.stop_profiling()
        :eprof.log(state.file_path)
        :eprof.analyze()
        :ok
      false ->
        Logger.warn("Start profiling first!")
        :error
    end
  end
end
