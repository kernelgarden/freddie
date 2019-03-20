defmodule <%= app_mod %>.Application do
  use Application

  require Logger

  def start(_type, _args) do
    Supervisor.start_link(
      [
        {Freddie, [activate_eprof: true, activate_fprof: true]}
      ],
      strategy: :one_for_one
    )
  end
end
