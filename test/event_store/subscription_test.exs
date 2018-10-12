defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionTest do
  use Commanded.EventStore.SubscriptionTestCase

  alias Commanded.EventStore.Adapters.Extreme.Storage

  setup do
    on_exit(fn ->
      Storage.reset!()
    end)

    :ok
  end

  defp event_store_wait(_default \\ nil), do: 1_000
end
