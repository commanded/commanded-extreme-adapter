defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionTest do
  use Commanded.EventStore.SubscriptionTestCase

  alias Commanded.EventStore.Adapters.Extreme.Storage

  setup do
    Storage.reset!()
  end

  defp event_store_wait(_default \\ nil), do: 5_000
end
