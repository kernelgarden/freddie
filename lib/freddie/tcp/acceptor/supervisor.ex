defmodule Freddie.TCP.Acceptor.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)
    Supervisor.init(make_children_list(), strategy: :one_for_one)
  end

  def handle_info({:exit, from, reason}, state) do
    Logger.error(fn -> "acceptor #{inspect(from)} is down. reason: #{inspect(reason)}" end)
    {:noreply, state}
  end

  def make_acceptor_name(idx) do
    String.to_atom("Acceptor #{idx}")
  end

  defp make_children_list do
    acceptor_pool_size = Application.get_env(:freddie, :acceptor_pool_size, 16)

    1..acceptor_pool_size
    |> Enum.map(fn idx ->
      %{
        id: make_acceptor_name(idx),
        start: {Freddie.TCP.Acceptor, :start_link, [idx]},
        type: :worker,
        shutdown: :brutal_kill
      }
    end)
  end
end
