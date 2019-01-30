defmodule Freddie.Session.Supervisor do
  use DynamicSupervisor

  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child() do
    DynamicSupervisor.start_child(__MODULE__, Freddie.Session)
  end

  @impl true
  def init(_args) do
    :ets.new(:user_sessions, [:set, :public, :named_table])

    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
