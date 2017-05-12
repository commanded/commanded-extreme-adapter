ExUnit.start()

# configure this event store adapter for Commanded
Application.put_env(:commanded, :event_store_adapter, Commanded.EventStore.Adapters.Extreme)
Application.put_env(:commanded, :reset_storage, &Commanded.EventStore.Adapters.Extreme.ResetStorage.execute/0)
Application.put_env(:commanded, :event_store_wait, 10_000)
