use Mix.Config

config :ex_unit,
  capture_log: true,
  assert_receive_timeout: 5_000

config :commanded, :event_store_adapter, Commanded.EventStore.Adapters.Extreme

config :commanded_extreme_adapter,
  serializer: Commanded.Serialization.JsonSerializer,
  stream_prefix: "commandedtest"

config :extreme, :event_store,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit",
  reconnect_delay: 2_000,
  max_attempts: :infinity
