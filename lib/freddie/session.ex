defmodule Freddie.Session do
  @behaviour GenServer

  require Logger

  defstruct socket: nil, addr: nil, buffer: nil

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
    state = %Freddie.Session{buffer: Freddie.ByteBuffer.new()}
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
  def handle_info({:tcp, socket, data}, %Freddie.Session{buffer: buffer} = state) when socket != nil do
    Freddie.Session.Helper.activate_socket(socket)
    new_state = %Freddie.Session{state | buffer: Freddie.ByteBuffer.push(buffer, data)}
    # Echo back for test
    Freddie.Session.send(self(), data)
    Logger.info(fn -> "Received from #{state.addr} - current: #{byte_size(buffer.buf)}" end)
    {:noreply, new_state}
  end

  @doc """
  Outcomming data handler
  """
  @impl true
  def handle_info({:send, data}, state) do
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
