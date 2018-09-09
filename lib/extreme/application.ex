defmodule Commanded.EventStore.Adapters.Extreme.Application do
  use Application

  alias Commanded.EventStore.Adapters.Extreme.{
    Config,
    EventPublisher,
    SubscriptionsSupervisor,
    PubSub
  }

  @event_store Commanded.EventStore.Adapters.Extreme.EventStore

  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: PubSub, partitions: 1},
      %{
        id: Extreme,
        start: {Extreme, :start_link, [Config.event_store_settings(), [name: @event_store]]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },
      %{
        id: EventPublisher,
        start:
          {EventPublisher, :start_link, [
            @event_store,
            "$streams",
            [name: EventPublisher]
          ]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },
      SubscriptionsSupervisor
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: Commanded.EventStore.Adapters.Extreme.Supervisor
    )
  end
end
