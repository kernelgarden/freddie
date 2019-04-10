defmodule <%= app_mod %>.MixProject do
  use Mix.Project

  def project do
    [
      app: :<%= app_name %>,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],

      # Start EchoServer Applicaion
      mod: {<%= app_mod %>.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:freddie, "~> <%= freddie_version %>"}
    ]
  end
end
