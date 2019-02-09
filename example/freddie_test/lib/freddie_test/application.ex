defmodule FreddieTest.Application do
  use Application

  def start(_type, _args) do
    :fprof.trace([:start, verbose: true, procs: :all])

    spawn fn ->
      :timer.sleep(10_000)
      :fprof.trace(:stop)
      :fprof.profile()
      :fprof.analyse(totals: false, dest: 'prof.analysis')
    end
    Supervisor.start_link(
      [
        Freddie
      ],
      strategy: :one_for_one
    )
  end
end
