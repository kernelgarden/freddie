defmodule Freddie.MixProject do
  use Mix.Project

  def project do
    [
      app: :freddie,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :exprotobuf, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:connection, "~> 1.0.4"},
      {:poolboy, "~> 1.5"},
      {:gen_stage, "~> 0.14.1"},
      {:exprotobuf, "~> 1.2.9"},
      {:exprof, "~> 0.2.0"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "config/config.exs"],
      maintainers: ["kernelgarden"],
      license: ["Apache 2.0"]
    ]
  end

  defp description do
    """
    Socket framework for elixir.
    """
  end
end
