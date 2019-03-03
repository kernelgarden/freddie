defmodule FreddieTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :freddie_test,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FreddieTest.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:freddie, path: "../.."},
      {:ecto_sql, "~> 3.0.5"},
      {:mariaex, "~> 0.9.1"}
    ]
  end
end
