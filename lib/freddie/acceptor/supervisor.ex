defmodule Freddie.Acceptor.Supervisor do
  use Supervisor

  require Logger

  @num_of_acceptor 10

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)
    Supervisor.init(make_children_list(), strategy: :one_for_one)
  end

  def handle_info({:exit, from, reason}, state) do
    Logger.error(fn -> "acceptor #{inspect from} is down. reason: #{inspect reason}" end)
    {:noreply, state}
  end

  def make_acceptor_name(idx) do
    String.to_atom("Acceptor #{idx}")
  end

  defp make_children_list do
    1..@num_of_acceptor
    |> Enum.map(fn idx ->
      %{
        id: make_acceptor_name(idx),
        start: {Freddie.Acceptor, :start_link, [idx]},
        type: :worker,
        shutdown: :brutal_kill
      }
    end)
  end
end
