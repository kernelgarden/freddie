defmodule Freddie.Session do
  @behaviour GenServer

  require Logger

  defstruct socket: nil

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def set_socket(pid, socket) do
    Process.send(pid, {:socket_ready, socket}, [:noconnect])
  end

  def send(pid, data) do
    Process.send(pid, {:send, data}, [:noconnect])
  end

  @impl true
  def init(_opts) do
    state = %Freddie.Session{}
    {:ok, state}
  end

  @impl true
  def handle_info({:socket_ready, socket}, state) do
    state = %Freddie.Session{state | socket: socket}
    Logger.info(fn -> "Client #{socket} connected." end)
    {:noreply, state}
  end

  @doc """
  Incomming data handler
  """
  @impl true
  def handle_info({:tcp, socket, data}, state) when socket != nil do
    :inet.setopts(socket, [:binary, active: :once])
    Logger.info(fn -> "Client #{socket} send #{data}" end)
    {:noreply, state}
  end

  @doc """
  Outcomming data handler
  """
  @impl true
  def handle_info({:send, data}, state) do
    :ok = :gen_tcp.send(state.socket, data)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, state) do
    Logger.error(fn -> "Client #{socket} disconnected." end)
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(_info, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(_request, _, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(_request, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.error(fn -> "Client #{state.socket} terminated." end)
    :ok
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

end
