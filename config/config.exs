use Mix.Config

config :commanded, :event_store_adapter, Commanded.EventStore.Adapters.Extreme

import_config "#{Mix.env()}.exs"
