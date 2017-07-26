defmodule Commanded.EventStore.Adapters.Extreme.Application do
  use Application

  alias Commanded.EventStore.Adapters.Extreme.Config

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Extreme, [Config.event_store_settings(), [name: Commanded.EventStore.Adapters.Extreme.EventStore]]),
      worker(Commanded.EventStore.Adapters.Extreme, []),
    ]

    opts = [strategy: :one_for_one, name: Commanded.EventStore.Adapters.Extreme.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
