defmodule CodacyMetrics.MixProject do
  use Mix.Project

  def project do
    [
      app: :codacy_metrics,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CodacyMetrics.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.3.0"},
      {:jason, "~> 1.2"},
      {:memoize, "~> 1.3"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
