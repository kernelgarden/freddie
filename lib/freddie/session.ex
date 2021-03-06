defmodule Freddie.Session do
  @moduledoc """
  Freddie.Session is a single-ended endpoint that abstracts network connections with clients.
  You can perform Reliable, Unreliable communications based on TCP, RUDP protocol.
  """

  use GenServer

  require Logger

  alias __MODULE__
  alias Freddie.Context
  alias Freddie.Utils
  alias Freddie.Security.DiffieHellman
  alias Freddie.Security.Aes
  alias Freddie.Scheme.Common.ConnectionInfo

  @resend_queue_flush_time 16
  @max_resend_round 5

  @user_session_table :user_sessions

  defstruct socket: nil,
            addr: nil,
            buffer: <<>>,
            packet_handler_mod: nil,
            packet_types_mod: nil,

            # send queue
            send_queue: <<>>,
            is_send_queue_dirty: false,
            cur_resend_round: 1,

            # encryption
            is_established_encryption: false,
            server_private_key: 0,
            secret_key: <<>>

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc false
  def set_socket(pid, socket) do
    GenServer.cast(pid, {:socket_ready, socket})
  end

  @doc false
  def user_session_table, do: @user_session_table

  @doc """
  Returns the pid of the session process associated with the passed context.
  ## Examples
      case lookup_pid(context) do
        {:ok, pid} ->
          # do something

        other ->
          {:error, other}
      end
  """
  def lookup_pid(context) do
    session = Context.get_session(context)

    case :ets.lookup(@user_session_table, session.socket) do
      [{_, pid} | _] ->
        {:ok, pid}

      [] ->
        {:error, :unknown_socket}

      other ->
        {:error, other}
    end
  end

  @doc """
  Update the context bound to session.
  (This request is handled asynchronously through a cast call internally,
  so it is likely that other processes will temporarily refer to the previous context.)
  """
  def update_context(new_context) do
    case lookup_pid(new_context) do
      {:ok, pid} ->
        GenServer.cast(pid, {:update_context, new_context})

      other ->
        {:error, {:update_context, other}}
    end
  end

  @doc false
  def set_encryption(context, client_public_key) do
    case lookup_pid(context) do
      {:ok, pid} ->
        GenServer.cast(pid, {:establish_encryption, client_public_key})

      other ->
        {:error, {:set_encryption, other}}
    end
  end

  @doc """
  Sends packets to clients associated with passed context.
  """
  def send(context, msg, opts \\ []) do
    session = Context.get_session(context)

    opts = [is_established_encryption: session.is_established_encryption] ++ opts

    case Freddie.Scheme.Common.new_message(msg, session.secret_key, opts) do
      {:error, reason} ->
        Logger.error("Failed to send, reason: #{reason}")
        {:error, reason}

      data ->
        case lookup_pid(context) do
          {:ok, pid} ->
            GenServer.cast(pid, {:resend, data})

          other ->
            {:error, {:send, other}}
        end
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

    packet_types_mod =
      Application.get_env(
        :freddie,
        :packet_type_mod
      )

    session = %Session{
      buffer: <<>>,
      packet_handler_mod: packet_handler_mod,
      packet_types_mod: packet_types_mod,
      send_queue: <<>>,
      cur_resend_round: 1
    }

    context = Context.new(session)

    {:ok, context}
  end

  @impl true
  def handle_cast({:socket_ready, socket}, context) do
    Process.flag(:trap_exit, true)

    {:ok, {addr, _port}} = :inet.peername(socket)
    addr_str = :inet.ntoa(addr)

    new_context = Context.update_session(context, socket: socket, addr: addr_str)
    session = Context.get_session(new_context)

    :ets.insert(@user_session_table, {socket, self()})

    Session.Helper.activate_socket(socket)

    # To implement global timer??
    Process.send_after(self(), {:flush}, @resend_queue_flush_time)

    session.packet_handler_mod.dispatch(
      :connect,
      session.socket
    )

    # hand shake
    server_private_key = DiffieHellman.generate_private_key()
    server_public_key = DiffieHellman.generate_public_key(server_private_key)
    new_context = Context.update_session(new_context, server_private_key: server_private_key)

    key_exchange_info =
      ConnectionInfo.KeyExchangeInfo.new(
        generator: DiffieHellman.get_generator(),
        prime: Utils.Binary.to_big_integer(DiffieHellman.get_prime()),
        pub_key: Utils.Binary.to_big_integer(server_public_key)
      )

    connection_info = Freddie.Scheme.Common.ConnectionInfo.new(key_info: key_exchange_info)
    Session.send(new_context, connection_info)

    {:noreply, new_context}
  end

  @impl true
  def handle_cast({:resend, data}, context) do
    session = Context.get_session(context)

    new_context =
      Context.update_session(context,
        send_queue: <<session.send_queue::binary, data::binary>>,
        is_send_queue_dirty: true
      )

    {:noreply, new_context}
  end

  @impl true
  def handle_cast({:establish_encryption, client_public_key}, context) do
    session = Context.get_session(context)
    secret_key = DiffieHellman.generate_secret_key(client_public_key, session.server_private_key)
    aes_key = Aes.generate_aes_key(secret_key)

    new_context =
      Context.update_session(context, secret_key: aes_key, is_established_encryption: true)

    {:noreply, new_context}
  end

  @impl true
  def handle_cast({:update_context, new_context}, new_context) do
    {:noreply, new_context}
  end

  @impl true
  def handle_info({:flush}, context) do
    session = Context.get_session(context)

    {new_send_queue, new_dirty_flag, new_resend_round} =
      case session.is_send_queue_dirty do
        true ->
          case internal_send(session.socket, session.send_queue) do
            :ok ->
              # Logger.info("resend succcess! queue_size: #{byte_size(session.send_queue)}")
              {<<>>, false, 1}

            _ ->
              # Logger.info("resend fail! queue_size: #{byte_size(session.send_queue)}")
              {session.send_queue, true, get_max_resend_round(session.cur_resend_round)}
          end

        false ->
          {session.send_queue, false, session.cur_resend_round}
      end

    # add flow control??
    Process.send_after(self(), {:flush}, @resend_queue_flush_time * new_resend_round)

    new_context =
      Context.update_session(context,
        send_queue: new_send_queue,
        is_send_queue_dirty: new_dirty_flag,
        cur_resend_round: new_resend_round
      )

    {:noreply, new_context}
  end

  @doc """
  Incomming data handler
  """
  @impl true
  def handle_info(
        {:tcp, socket, data},
        %Context{session: %Session{buffer: buffer} = session} = context
      )
      when socket != nil do
    new_context =
      Context.set_session(context, %Session{session | buffer: <<buffer::binary, data::binary>>})

    new_context = Session.PacketHandler.on_read(new_context)

    {:noreply, new_context}
  end

  @impl true
  def handle_info({:tcp_passive, socket}, context) do
    Session.Helper.activate_socket(socket)
    {:noreply, context}
  end

  @impl true
  def handle_info({:inet_reply, _, :ok}, context) do
    # todo
    {:noreply, context}
  end

  @impl true
  def handle_info({:inet_reply, _, _status}, context) do
    # Logger.error("[Session] send failed #{inspect status}")
    {:noreply, context}
  end

  @impl true
  def handle_info(:shutdown, context) do
    {:stop, :normal, context}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, context) do
    {:stop, :normal, context}
  end

  @impl true
  def handle_info({:tcp_error, _socket, _reason}, context) do
    # todo: handle errors
    {:noreply, context}
  end

  @impl true
  def handle_info(msg, context) do
    Logger.warn("Received unknown msg!!! - #{inspect(msg)}")
    {:noreply, context}
  end

  @impl true
  def handle_call(_request, _, context) do
    {:reply, :ok, context}
  end

  @impl true
  def terminate(_reason, context) do
    session = Context.get_session(context)
    # Logger.error(fn -> "Client #{session.addr} terminated." end)
    session.packet_handler_mod.dispatch(
      :disconnect,
      session.socket
    )

    :ets.delete(@user_session_table, session.socket)
    :ok
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
