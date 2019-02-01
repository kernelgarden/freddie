defmodule Freddie.Listener do
  use GenServer, restart: :transient

  require Logger

  defstruct listen_socket: nil, acceptor_ref: nil

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  @spec init(keyword()) :: {:ok, Freddie.Listener.t()} | {:stop, atom()}
  def init(args) do
    port = Keyword.get(args, :port)
    opts = [:binary, reuseaddr: true, keepalive: true, active: false, backlog: 1024]

    case :gen_tcp.listen(port, opts) do
      {:ok, listen_socket} ->
        Logger.info(fn -> "Listen on #{port}" end)
        :ets.insert(:listen_socket, {:sock, listen_socket})
        {:ok, nil}

      {:error, reason} ->
        Logger.error(fn -> "Cannot listen: #{reason}" end)
        {:stop, reason}
    end
  end

  # Todo: add more process...
end
