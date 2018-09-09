defmodule Commanded.EventStore.Adapters.Extreme.Mixfile do
  use Mix.Project

  @version "0.5.2"

  def project do
    [
      app: :commanded_extreme_adapter,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger
      ],
      mod: {Commanded.EventStore.Adapters.Extreme.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:commanded, ">= 0.16.0", runtime: false},
      {:extreme, "~> 0.11"},
      {:hackney, "~> 1.8.0", override: true},
      {:httpoison, "~> 0.11.1"},

      # Test & build tooling
      {
        :docker,
        github: "bearice/elixir-docker",
        tag: "03809fc594b9706c106fc28b7ef03c2dbde2fe93",
        only: :test
      },
      {:ex_doc, "~> 0.15", only: :dev},
      {:mix_test_watch, "~> 0.6", only: :dev}
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
