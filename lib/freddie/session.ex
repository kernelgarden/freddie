defmodule Freddie.Session do
  use GenServer

  require Logger

  defstruct socket: nil, addr: nil, buffer: <<>>, packet_handler_mod: nil, send_queue: []

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def set_socket(pid, socket) do
    Process.send(pid, {:socket_ready, socket}, [:noconnect])
  end

  def send(socket, data) do
    # Todo: error handling
    [{_, pid}] = :ets.lookup(:user_sessions, socket)
    Process.send(pid, {:send, data}, [:noconnect])
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :temporary
    }
  end

  @impl true
  def init(_opts) do
    packet_handler_mod =
      Application.get_env(
        :freddie,
        :packet_handler_mod
      )

    state = %Freddie.Session{buffer: <<>>, packet_handler_mod: packet_handler_mod}
    {:ok, state}
  end

  @impl true
  def handle_info({:socket_ready, socket}, state) do
    {:ok, {addr, _port}} = :inet.peername(socket)
    addr_str = :inet.ntoa(addr)
    state = %Freddie.Session{state | socket: socket, addr: addr_str}
    #Logger.info(fn -> "Client #{state.addr} connected." end)

    :ets.insert(:user_sessions, {socket, self()})

    Freddie.Session.Helper.activate_socket(socket)

    {:noreply, state}
  end

  @doc """
  Incomming data handler
  """
  @impl true
  def handle_info({:tcp, socket, data}, %Freddie.Session{buffer: buffer} = session)
      when socket != nil do
    #new_session = %Freddie.Session{session | buffer: <<buffer::binary, data::binary>>}
    #new_session = Freddie.Session.PacketHandler.onRead(new_session)
    new_session = session

    # Echo back for test
    #Freddie.Session.send(socket, data)
    #Freddie.Transport.port_cmd(socket, data)
    :gen_tcp.send(socket, data)
    #Logger.info(fn -> "Received from #{state.addr} - current: #{byte_size(buffer.buf)}" end)

    {:noreply, new_session}
  end

  @impl true
  def handle_info({:tcp_passive, socket}, session) do
    Freddie.Session.Helper.activate_socket(socket)
    {:noreply, session}
  end

  @doc """
  Outcomming data handler
  """
  @impl true
  def handle_info({:send, data}, state) do
    #case :gen_tcp.send(state.socket, data) do
    #  :ok -> :ok
    #  error -> error
    #end
    true = Freddie.Transport.port_cmd(state.socket, data)

    {:noreply, state}
  end

  @impl true
  def handle_info({:inet_reply, _, :ok}, state) do
    #todo
    {:noreply, state}
  end

  @impl true
  def handle_info({:inet_reply, _, status}, _state) do
    exit({:session, :send_failed, status})
  end

  @impl true
  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
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
    #Logger.error(fn -> "Client #{state.addr} terminated." end)
    :ets.delete(:user_sessions, state.socket)
    :ok
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
