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

  def command(command, opts \\ []) do
    :poolboy.transaction(
      __MODULE__,
      fn redix_pid ->
        Redix.command(redix_pid, command, opts)
      end
    )
  end

  def noreply_command(command, opts \\ []) do
    :poolboy.transaction(
      __MODULE__,
      fn redix_pid ->
        Redix.noreply_command(redix_pid, command, opts)
      end
    )
  end

  def pipeline(command, opts \\ []) do
    :poolboy.transaction(
      __MODULE__,
      fn redix_pid ->
        Redix.pipeline(redix_pid, command, opts)
      end
    )
  end

  def noreply_pipeline(command, opts \\ []) do
    :poolboy.transaction(
      __MODULE__,
      fn redix_pid ->
        Redix.noreply_pipeline(redix_pid, command, opts)
      end
    )
  end

  def transaction_pipeline(command, opts \\ []) do
    :poolboy.transaction(
      __MODULE__,
      fn redix_pid ->
        Redix.transaction_pipeline(redix_pid, command, opts)
      end
    )
  end
end
