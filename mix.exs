defmodule Commanded.EventStore.Adapters.Extreme.Mixfile do
  use Mix.Project

  @version "0.6.0"

  def project do
    [
      app: :commanded_extreme_adapter,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test,
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test),
    do: [
      "deps/commanded/test/event_store",
      "deps/commanded/test/support",
      "lib",
      "test/support"
    ]

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:commanded, "~> 0.18", runtime: Mix.env() == :test},
      {:extreme, "~> 0.13"},
      {:hackney, "~> 1.15", override: true},
      {:httpoison, "~> 1.2 or ~> 1.3"},

      # Optional dependencies
      {:jason, "~> 1.1", optional: true},

      # Test & build tooling
      {
        :docker,
        github: "bearice/elixir-docker",
        tag: "03809fc594b9706c106fc28b7ef03c2dbde2fe93",
        only: :test
      },
      {:ex_doc, "~> 0.19", only: :dev},
      {:mix_test_watch, "~> 0.9", only: :dev},
      {:mox, "~> 0.4", only: :test}
    ]
  end

  defp description do
    """
    Extreme event store adapter for Commanded
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      maintainers: ["Ben Smith"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/commanded/commanded-extreme-adapter",
        "Docs" => "https://hexdocs.pm/commanded_extreme_adapter/"
      }
    ]
  end
end
