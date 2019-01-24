defmodule Freddie do
  @moduledoc """
  Documentation for Freddie.
  """

  use Supervisor

  require Logger

  def start_link(opts \\ []) do
    Logger.info(fn -> "Start Freddie..." end)
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    port = Application.get_env(:freddie, :port)

    children = [
      {Freddie.Acceptor, [port: port]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
