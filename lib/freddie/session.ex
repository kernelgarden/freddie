defmodule Freddie.Session do
  use GenServer

  require Logger

  @resend_queue_flush_time 16
  @max_resend_round 5

  defstruct socket: nil,
            addr: nil,
            buffer: <<>>,
            packet_handler_mod: nil,
            send_queue: <<>>,
            is_send_queue_dirty: false,
            cur_resend_round: 1

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def set_socket(pid, socket) do
    Process.send(pid, {:socket_ready, socket}, [:noconnect])
  end

  def send(socket, msg) do
    case Freddie.Scheme.Common.new_message(msg) do
      data ->
        case internal_send(socket, data) do
          :port_is_busy ->
            case :ets.lookup(:user_sessions, socket) do
              [{_, pid} | _] ->
                GenServer.cast(pid, {:resend, data})

              [] ->
                {:error, {:send, :unknown_socket}}

              other ->
                other
            end

          other ->
            other
        end

      {:error, reason} ->
        Logger.error("Failed to send, reason: #{reason}")
        {:error, reason}
    end
  end

  defp internal_send(socket, data) do
    case Freddie.Transport.port_cmd(socket, data) do
      :ok ->
        :ok

      :port_is_busy ->
        :port_is_busy

      error ->
        # Logger.error("error occurred #{inspect error}")
        error
    end
  end

  defp get_max_resend_round(cur_round) do
    max(@max_resend_round, cur_round + 1)
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

    state = %Freddie.Session{
      buffer: <<>>,
      packet_handler_mod: packet_handler_mod,
      send_queue: <<>>,
      cur_resend_round: 1
    }

    {:ok, state}
  end

  @impl true
  def handle_info({:socket_ready, socket}, state) do
    Process.flag(:trap_exit, true)

    {:ok, {addr, _port}} = :inet.peername(socket)
    addr_str = :inet.ntoa(addr)
    state = %Freddie.Session{state | socket: socket, addr: addr_str}

    :ets.insert(:user_sessions, {socket, self()})

    Freddie.Session.Helper.activate_socket(socket)

    # To implement global timer??
    Process.send_after(self(), {:flush}, @resend_queue_flush_time)

    state.packet_handler_mod.dispatch(
      :connect,
      state.socket
    )

    # hand shake


    {:noreply, state}
  end

  @doc """
  Incomming data handler
  """
  @impl true
  def handle_info({:tcp, socket, data}, %Freddie.Session{buffer: buffer} = session)
      when socket != nil do
    new_session = %Freddie.Session{session | buffer: <<buffer::binary, data::binary>>}
    new_session = Freddie.Session.PacketHandler.onRead(new_session)

    {:noreply, new_session}
  end

  @impl true
  def handle_info({:flush}, state) do
    {new_send_queue, new_dirty_flag, new_resend_round} =
      case state.is_send_queue_dirty do
        true ->
          case internal_send(state.socket, state.send_queue) do
            :ok ->
              # Logger.info("resend succcess! queue_size: #{byte_size(state.send_queue)}")
              {<<>>, false, 1}

            _ ->
              # Logger.info("resend fail! queue_size: #{byte_size(state.send_queue)}")
              {state.send_queue, true, get_max_resend_round(state.cur_resend_round)}
          end

        false ->
          {state.send_queue, false, state.cur_resend_round}
      end

    # add flow control??
    Process.send_after(self(), {:flush}, @resend_queue_flush_time * new_resend_round)

    {:noreply,
     %Freddie.Session{
       state
       | send_queue: new_send_queue,
         is_send_queue_dirty: new_dirty_flag,
         cur_resend_round: new_resend_round
     }}
  end

  @impl true
  def handle_cast({:resend, data}, state) do
    new_state = %Freddie.Session{
      state
      | send_queue: <<data::binary, state.send_queue::binary>>,
        is_send_queue_dirty: true
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:tcp_passive, socket}, session) do
    Freddie.Session.Helper.activate_socket(socket)
    {:noreply, session}
  end

  @impl true
  def handle_info({:inet_reply, _, :ok}, state) do
    # todo
    {:noreply, state}
  end

  @impl true
  def handle_info({:inet_reply, _, status}, state) do
    # Logger.error("[Session] send failed #{inspect status}")
    {:noreply, state}
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
  def handle_info({:tcp_error, _socket, reason}, state) do
    # todo: handle errors
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warn("Received unknown msg!!! - #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call(_request, _, state) do
    {:reply, :ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    # Logger.error(fn -> "Client #{state.addr} terminated." end)
    state.packet_handler_mod.dispatch(
      :disconnect,
      state.socket
    )

    :ets.delete(:user_sessions, state.socket)
    :ok
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
