defmodule Freddie.Session do
  @behaviour GenServer

  require Logger

  defstruct socket: nil, addr: nil

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def set_socket(pid, socket) do
    Process.send(pid, {:socket_ready, socket}, [:noconnect])
  end

  def send(pid, data) do
    Process.send(pid, {:send, data}, [:noconnect])
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
    }
  end

  @impl true
  def init(_opts) do
    state = %Freddie.Session{}
    {:ok, state}
  end

  @impl true
  def handle_info({:socket_ready, socket}, state) do
    Freddie.Session.Helper.activate_socket(socket)

    {:ok, {addr, _port}} = :inet.peername(socket)
    addr_str = :inet.ntoa(addr)
    state = %Freddie.Session{state | socket: socket, addr: addr_str}
    Logger.info(fn -> "Client #{state.addr} connected." end)
    {:noreply, state}
  end

  @doc """
  Incomming data handler
  """
  @impl true
  def handle_info({:tcp, socket, data}, state) when socket != nil do
    Freddie.Session.Helper.activate_socket(socket)
    Logger.info(fn -> "Client #{state.addr} send <#{data}>" end)
    # Echo back for test
    Freddie.Session.send(self(), data)
    {:noreply, state}
  end

  @doc """
  Outcomming data handler
  """
  @impl true
  def handle_info({:send, data}, state) do
    Logger.info(fn -> "Send to Client #{state.addr} send <#{data}>" end)
    case :gen_tcp.send(state.socket, data) do
      :ok -> :ok
      error -> error
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.error(fn -> "Client #{state.addr} disconnected." end)
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
    Logger.error(fn -> "Client #{state.addr} terminated." end)
    :ok
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

end
