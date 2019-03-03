defmodule FreddieTest.Application do
  use Application

  require Logger

  def start(_type, args) do
    Supervisor.start_link(
      [
        FreddieTest.Repo,
        {Freddie, [activate_eprof: true, activate_fprof: true]}
      ],
      strategy: :one_for_one
    )
  end
end
