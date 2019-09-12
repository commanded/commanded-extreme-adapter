defmodule ExtremeApplication do
  use Commanded.Application,
    otp_app: :commanded_extreme_adapter

  def init(config) do
    stream_prefix = "commandedtest#{String.replace(UUID.uuid4(), "-", "")}"
    config = put_in(config, [:event_store, :stream_prefix], stream_prefix)

    {:ok, config}
  end
end
