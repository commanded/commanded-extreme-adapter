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
      mod: {Commanded.EventStore.Adapters.Extreme.Application, []},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:commanded, "~> 0.10", runtime: false},
      {:docker, github: "bearice/elixir-docker", tag: "03809fc594b9706c106fc28b7ef03c2dbde2fe93", only: :test},
      {:extreme, github: "slashdotdash/extreme", tag: "6c0036909dcac2a79dd00f707d29fe7e0128aa5a"},
      {:hackney, "~> 1.8.0", override: true},
      {:httpoison, "~> 0.11.1"},
      {:mix_test_watch, "~> 0.2", only: :dev},
    ]
  end
end
