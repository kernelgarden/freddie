defmodule Freddie do
  @moduledoc """
  Documentation for Freddie.
  """

  use Supervisor

  require Logger

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args \\ []) do
    Logger.info(fn -> "Start Freddie..." end)
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    port = Application.get_env(:freddie, :port, 5050)

    activate_fprof = Keyword.get(args, :activate_fprof, false)
    activate_eprof = Keyword.get(args, :activate_eprof, false)

    children = build_children(port, activate_fprof, activate_eprof)
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp build_children(port, activate_fprof, activate_eprof) do
    children = []

    # Quantum Scheduler
    children =
      [
        # {Freddie.Scheduler, []}
      ] ++ children

    # Eprof
    children =
      case activate_eprof do
        true -> [Freddie.Utils.Eprof] ++ children
        false -> children
      end

    # Session Supervisor and Listener Upervisor
    children =
      [
        Freddie.Session.Supervisor,
        {Freddie.Listener.Supervisor, [port: port]}
      ] ++ children

    # Fprof
    children =
      case activate_fprof do
        true -> [Freddie.Utils.Fprof] ++ children
        false -> children
      end

    children
  end
end
