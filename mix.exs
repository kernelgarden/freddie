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
      description: description(),
      docs: docs()
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
      {:poolboy, "~> 1.5"},
      {:gen_stage, "~> 0.14.1"},
      {:exprotobuf, "~> 1.2.9"},
      {:exprof, "~> 0.2.0"},
      {:timex, "~> 3.0"},
      {:enum_type, "~> 1.0.1"},
      {:redix, ">= 0.0.0"},
      {:ex_doc, "~> 0.19.3", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "config/config.exs"],
      maintainers: ["kernelgarden"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/kernelgarden/freddie"}
    ]
  end

  defp description do
    """
    Socket framework for elixir.
    """
  end

  defp docs do
    [
      main: "Freddie",
      formatters: ["html", "epub"],
      groups_for_modules: groups_for_modules(),
      extra_section: "GUIDES",
      extras: extras()
    ]
  end

  defp extras do
    ["README.md"]
  end

  defp groups_for_modules do
    [
      Utils: [
        Freddie.Utils,
        Freddie.Utils.Binary,
        Freddie.Utils.Eprof,
        Freddie.Utils.Fprof
      ]
    ]
  end
end
