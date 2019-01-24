defmodule Freddie.Acceptor do
  use GenServer

  require Logger

  require Record
  import Record

  defrecord :state,
    listen_socket: nil,
    acceptor_ref: nil

  def start_link(args) do
    IO.inspect(args)
    GenServer.start_link(__MODULE__, args)
  end

  #def child_spec(args) do
  #  %{
  #    id: __MODULE__,
  #    start: {__MODULE__, :start_link, args},
  #  }
  #end

  @impl true
  def init(args) do
    port = Keyword.get(args, :port)
    opts = [:binary, reuseaddr: true, keepalive: true, backlog: 30, active: false]
    case :gen_tcp.listen(port, opts) do
      {:ok, listen_socket} ->
        Logger.info(fn -> "Listen on #{port}" end)
        {:ok, ref} = :prim_inet.async_accept(listen_socket, -1)
        {:ok, state(listen_socket: listen_socket, acceptor_ref: ref)}
      {:error, reason} ->
        Logger.error(fn -> "Cannot listen: #{reason}" end)
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:stop, _, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info({:inet_async, listen_socket, _ref, {:ok, client_socket}}, state) do
    try do
      case set_socket(listen_socket, client_socket) do
        :ok ->
          :ok
        {:error, reason} ->
          {:stop, {:badtcp, {:set_socks, reason}}, state}
      end

      {:ok, pid} = Freddie.Session.Supervisor.start_child()
      :ok = :gen_tcp.controlling_process(client_socket, pid)
      Freddie.Session.set_socket(pid, client_socket)

      # 다른 커넥션을 맺을 준비를 한다
      case :prim_inet.async_accept(listen_socket, -1) do
        {:ok, new_ref} ->
          {:noreply, state(state, acceptor_ref: new_ref), :hibernate}
        {:error, new_ref} ->
          {:stop, {:badtcp, {:async_accept, :inet.format_error(new_ref)}}, state}
      end

    catch
      :exit, reason ->
        {:stop, {:badtcp, reason}, state}
    end
  end

  defp set_socket(listen_socket, client_socket) do
    true = :inet_db.register_socket(client_socket, :inet_tcp)

    case :prim_inet.getopts(
      listen_socket, [:active, :nodelay, :keepalive, :delay_send, :priority, :tos]) do
      {:ok, opts} ->
        case :prim_inet.setopts(client_socket, opts) do
          :ok ->
            :ok
          error ->
            :gen_tcp.close(client_socket)
            error
        end
      error ->
        :gen_tcp.close(client_socket)
        error
    end
  end
end
