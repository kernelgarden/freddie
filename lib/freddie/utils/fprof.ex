defmodule Freddie.Utils.Fprof do
  use GenServer

  require Logger

  defstruct is_active: false, file_path: ''

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start() do
    GenServer.cast(__MODULE__, {:start})
  end

  def stop() do
    GenServer.cast(__MODULE__, {:stop})
  end

  def kill() do
    GenServer.cast(__MODULE__, {:kill})
  end

  @impl true
  @spec init(keyword()) :: {:ok, Freddie.Utils.Fprof.t()}
  def init(args) do
    Logger.info("Activate fprof server")
    file_path = Keyword.get(args, :path, 'fprof.analysis')
    {:ok, %Freddie.Utils.Fprof{is_active: false, file_path: file_path}}
  end

  @impl true
  def handle_cast({:start}, state) do
    case state.is_active do
      false ->
        Logger.info("Start profiling with fprof")
        :fprof.trace([:start, verbose: true, procs: :all])
        {:noreply, %Freddie.Utils.Fprof{state | is_active: true}}

      true ->
        Logger.warn("Already started fprof!!!")
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:stop}, state) do
    case stop_profiling(state) do
      :ok ->
        {:noreply, %Freddie.Utils.Fprof{state | is_active: false}}

      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:kill}, state) do
    Logger.info("Terminate fprof server")
    if state.is_active, do: stop_profiling(state)

    {:stop, :normal, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warn("Received unknown msg!!! - #{inspect(msg)}")
    {:noreply, state}
  end

  defp stop_profiling(state) do
    case state.is_active do
      true ->
        :fprof.trace(:stop)
        :fprof.profile()
        :fprof.analyse(totals: false, dest: state.file_path)
        :ok

      false ->
        Logger.warn("Start profiling first!")
        :error
    end
  end
end
