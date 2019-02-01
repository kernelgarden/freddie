defmodule Freddie.Listener.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    port = Keyword.get(args, :port)

    :ets.new(:listen_socket, [:set, :public, :named_table])

    children = [
      {Freddie.Listener, [port: port]},
      Freddie.Acceptor.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 10, max_seconds: 10)
  end
end
