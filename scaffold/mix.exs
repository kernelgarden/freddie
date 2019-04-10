defmodule FreddieScaffold.MixProject do
  use Mix.Project

  def project do
    [
      app: :freddie_scaffold,
      version: "0.1.5",
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19.3", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "config/config.exs"],
      maintainers: ["kernelgarden"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/kernelgarden/freddie"},
      files: ~w(lib templates mix.exs README.md)
    ]
  end

  defp description() do
    """
    Scaffolding tool for freddie.
    """
  end

  defp docs do
    [
      main: "readme",
      formatters: ["html", "epub"],
      extras: extras()
    ]
  end

  defp extras do
    ["README.md"]
  end
end
