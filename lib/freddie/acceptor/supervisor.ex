defmodule Freddie.Acceptor.Supervisor do
  use Supervisor

  @num_of_acceptor 10

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Supervisor.init(make_children_list(), strategy: :one_for_one)
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
