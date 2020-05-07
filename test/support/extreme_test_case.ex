defmodule Commanded.ExtremeTestCase do
  use ExUnit.CaseTemplate

  alias Commanded.EventStore.Adapters.Extreme

  setup do
    config = [
      serializer: Commanded.Serialization.JsonSerializer,
      stream_prefix: "commandedtest" <> UUID.uuid4(:hex),
      extreme: [
        db_type: :node,
        host: "localhost",
        port: 1113,
        username: "admin",
        password: "changeit",
        reconnect_delay: 2_000,
        max_attempts: :infinity
      ]
    ]

    {:ok, child_spec, event_store_meta} = Extreme.child_spec(ExtremeApplication, config)

    for child <- child_spec do
      start_supervised!(child)
    end

    [event_store_meta: event_store_meta]
  end
end
