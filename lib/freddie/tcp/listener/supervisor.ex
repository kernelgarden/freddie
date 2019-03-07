defmodule Freddie.TCP.Listener.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    port = Keyword.get(args, :port)

    :ets.new(:listen_socket, [:set, :public, :named_table])

    children = [
      {Freddie.TCP.Listener, [port: port]},
      Freddie.TCP.Acceptor.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 10, max_seconds: 10)
  end

  def handle_info({:EXIT, from, reason}, state) do
    Logger.error(fn -> "#{inspect(from)} is down. reason: #{inspect(reason)}" end)
    {:noreply, state}
  end
end
