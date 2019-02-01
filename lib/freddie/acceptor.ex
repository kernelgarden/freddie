defmodule Freddie.Acceptor do
  use GenServer, restart: :transient

  require Logger

  defstruct listen_socket: nil, acceptor_ref: nil, acceptor_idx: 0

  def start_link(idx) do
    GenServer.start_link(__MODULE__, [idx],
      name: Freddie.Acceptor.Supervisor.make_acceptor_name(idx)
    )
  end

  # Todo: tune buf size

  @impl true
  def init(idx) do
    [{_, listen_socket}] = :ets.lookup(:listen_socket, :sock)
    GenServer.cast(self(), {:init, listen_socket})
    {:ok, %Freddie.Acceptor{acceptor_idx: idx}}
  end

  @impl true
  def handle_call(:stop, _, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_cast({:init, listen_socket}, _state) do
    {:ok, ref} = :prim_inet.async_accept(listen_socket, -1)
    {:noreply, %Freddie.Acceptor{listen_socket: listen_socket, acceptor_ref: ref}}
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

      # Todo: change this to session with session pool
      {:ok, pid} = Freddie.Session.Supervisor.start_child()
      :ok = :gen_tcp.controlling_process(client_socket, pid)
      Freddie.Session.set_socket(pid, client_socket)

      # 다른 커넥션을 맺을 준비를 한다
      accept(state)
    catch
      :exit, reason ->
        {:stop, {:badtcp, reason}, state}
    end
  end

  @impl true
  def handle_info({:inet_async, _listen_socket, _ref, {:error, reason}}, state) do
    case reason do
      :closed ->
        {:stop, :normal, state}

      :econnaborted ->
        accept(state)

      _ ->
        {:stop, {:accept_failed, reason}, state}
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  defp accept(state) do
    case :prim_inet.async_accept(state.listen_socket, -1) do
      {:ok, new_ref} ->
        {:noreply, %Freddie.Acceptor{state | acceptor_ref: new_ref}}

      :error ->
        {:stop, {:badtcp, {:async_accept}}, state}
    end
  end

  defp set_socket(listen_socket, client_socket) do
    true = :inet_db.register_socket(client_socket, :inet_tcp)

    case :prim_inet.getopts(listen_socket, [
           :active,
           :nodelay,
           :keepalive,
           :delay_send,
           :priority,
           :tos
         ]) do
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
