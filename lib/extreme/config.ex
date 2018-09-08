defmodule Commanded.EventStore.Adapters.Extreme.Config do
  def event_store_settings do
    Application.get_env(:extreme, :event_store) ||
      raise ArgumentError, "expects :extreme to be configured in environment"
  end

  def serializer do
    Application.get_env(:commanded_extreme_adapter, :serializer) ||
      raise ArgumentError, "expects :serializer to be configured in environment"
  end
end
