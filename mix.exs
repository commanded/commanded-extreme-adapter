defmodule Commanded.EventStore.Adapters.Extreme.Mixfile do
  use Mix.Project

  def project do
    [
      app: :commanded_extreme_adapter,
      version: "0.1.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
      ],
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:commanded, path: "~/src/commanded", runtime: false},
      {:docker, github: "bearice/elixir-docker", only: :test},
      {:extreme, "~> 0.8"},
      {:hackney, "~> 1.6.0", override: true},
      {:httpoison, "~> 0.8.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
    ]
  end
end
