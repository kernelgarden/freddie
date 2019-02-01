defmodule Freddie.Acceptor.Supervisor do
  use Supervisor

  @num_of_acceptor 10

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl true
  def init(_args) do
    Supervisor.init(make_children_list(), strategy: :one_for_one)
  end

  defp make_children_list do
    1..@num_of_acceptor
    |> Enum.map(fn idx ->
      %{
        id: String.to_atom("Acceptor #{idx}"),
        start: {Freddie.Acceptor, :start_link, []},
        type: :worker,
        shutdown: :brutal_kill
      }
    end)
  end

end
