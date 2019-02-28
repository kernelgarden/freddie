defmodule Freddie.Redis.Pool do
  require Logger

  def child_spec(args) do
    host = Keyword.get(args, :host)
    port = Keyword.get(args, :port)
    pool_size = Keyword.get(args, :pool_size)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Redix,
        size: pool_size
      ],
      host: host,
      port: port
    )
  end

  def command(command) do
    :poolboy.transaction(
      __MODULE__,
      fn redix_pid ->
        Redix.command(redix_pid, command)
      end
    )
  end
end
