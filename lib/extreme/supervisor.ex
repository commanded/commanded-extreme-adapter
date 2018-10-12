defmodule Commanded.EventStore.Adapters.Extreme.Supervisor do
  use Supervisor

  alias Commanded.EventStore.Adapters.Extreme.{
    Config,
    EventPublisher,
    SubscriptionsSupervisor,
    PubSub
  }

  @event_store Commanded.EventStore.Adapters.Extreme.EventStore

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    event_store_settings = Config.event_store_settings()
    all_stream = Config.all_stream()

    children = [
      {Registry, keys: :duplicate, name: PubSub, partitions: 1},
      %{
        id: Extreme,
        start: {Extreme, :start_link, [event_store_settings, [name: @event_store]]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },
      # {EventPublisher, @event_store, all_stream, [name: EventPublisher]},
      %{
        id: EventPublisher,
        start:
          {EventPublisher, :start_link,
           [
             @event_store,
             all_stream,
             [name: EventPublisher]
           ]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      },
      SubscriptionsSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
