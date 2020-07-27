defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionTest do
  alias Commanded.EventStore.Adapters.Extreme

  use Commanded.ExtremeTestCase
  use Commanded.EventStore.SubscriptionTestCase, event_store: Extreme

  describe "multiple subscribers to stream" do
    test "should receive `:subscribed` message if the subscriber limit is not reached ", %{
      event_store: event_store,
      event_store_meta: event_store_meta
    } do
      eventstore_options = [subscriber_max_count: 2]

      {:ok, first_subscription} =
        event_store.subscribe_to(
          event_store_meta,
          "stream_multiple_1",
          "subscriber",
          self(),
          :origin,
          eventstore_options
        )

      {:ok, second_subscription} =
        event_store.subscribe_to(
          event_store_meta,
          "stream_multiple_1",
          "subscriber",
          self(),
          :origin,
          eventstore_options
        )

      assert_receive {:subscribed, ^first_subscription}
      assert_receive {:subscribed, ^second_subscription}
    end

    test "should receive `:too_many_subscribers` message if the subscriber limit is reached ", %{
      event_store: event_store,
      event_store_meta: event_store_meta
    } do
      eventstore_options = [subscriber_max_count: 2]

      {:ok, _first_subscription} =
        event_store.subscribe_to(
          event_store_meta,
          "stream_multiple_2",
          "subscriber",
          self(),
          :origin,
          eventstore_options
        )

      {:ok, _second_subscription} =
        event_store.subscribe_to(
          event_store_meta,
          "stream_multiple_2",
          "subscriber",
          self(),
          :origin,
          eventstore_options
        )

      assert {:error, :too_many_subscribers} ==
               event_store.subscribe_to(
                 event_store_meta,
                 "stream_multiple_2",
                 "subscriber",
                 self(),
                 :origin,
                 eventstore_options
               )
    end
  end

  defp event_store_wait(_default \\ nil), do: 5_000
end
