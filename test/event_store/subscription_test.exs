defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionTest do
  use Commanded.EventStore.SubscriptionTestCase, application: ExtremeApplication

  defp event_store_wait(_default \\ nil), do: 5_000
end
