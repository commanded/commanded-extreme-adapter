defmodule Commanded.EventStore.Adapters.Extreme.Supervisor do
  use Supervisor

  alias Commanded.EventStore.Adapters.Extreme.Config
  alias Commanded.EventStore.Adapters.Extreme.EventPublisher
  alias Commanded.EventStore.Adapters.Extreme.SubscriptionsSupervisor

  def start_link({event_store, config}) do
    name = Module.concat([event_store, Supervisor])

    Supervisor.start_link(__MODULE__, {event_store, config}, name: name)
  end

  @impl Supervisor
  def init({event_store, config}) do
    all_stream = Config.all_stream(config)
    extreme_config = Keyword.get(config, :extreme)
    serializer = Config.serializer(config)

    event_store_name = Module.concat([event_store, Extreme])
    event_publisher_name = Module.concat([event_store, EventPublisher])
    pubsub_name = Module.concat([event_store, PubSub])
    subscriptions_name = Module.concat([event_store, SubscriptionsSupervisor])

    children = [
      {Registry, keys: :duplicate, name: pubsub_name, partitions: 1},
      %{
        id: Extreme,
        start: {Extreme, :start_link, [extreme_config, [name: event_store_name]]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },
      %{
        id: event_publisher_name,
        start:
          {EventPublisher, :start_link,
           [
             {event_store_name, pubsub_name, all_stream, serializer},
             [name: event_publisher_name]
           ]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },
      {SubscriptionsSupervisor, name: subscriptions_name}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
