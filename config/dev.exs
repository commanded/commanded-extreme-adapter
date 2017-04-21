use Mix.Config

config :extreme, :event_store,
  db_type: :node,
  host: "localhost",
  port: 1113,
  username: "admin",
  password: "changeit",
  reconnect_delay: 2_000,
  max_attempts: :infinity

config :commanded_extreme_adapter,
  serializer: Commanded.Serialization.JsonSerializer,
  streams_prefix: "commanded-dev"
