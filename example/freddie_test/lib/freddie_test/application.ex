defmodule FreddieTest.Application do
  use Application

  def start(_type, _args) do
    #:eprof.start_profiling([self()])

    #spawn fn ->
    #  :timer.sleep(20_000)
    #  :eprof.stop_profiling()
    #  :eprof.log("eprof.analysis")
    #  :eprof.analyze()
    #end

    Supervisor.start_link(
      [
        Freddie
      ],
      strategy: :one_for_one
    )
  end
end
