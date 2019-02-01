defmodule FreddieTest.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link(
      [
        Freddie
      ],
      strategy: :one_for_one
    )
  end
end
