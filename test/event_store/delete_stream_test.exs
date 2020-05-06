defmodule Commanded.EventStore.Adapters.Extreme.DeleteStreamTest do
  use ExUnit.Case

  alias Extreme.Msg, as: ExMsg

  setup do
    {:ok, pid} = Extreme.start_link(config())

    [server: pid]
  end

  describe "write events" do
    setup [:write_events]

    test "can be read", %{server: server, stream_id: stream_id} do
      {:ok, events} = read_events(server, stream_id)

      assert length(events) == 3
    end

    test "subscribe to stream", %{server: server, stream_id: stream_id} do
      name = "test-subscription-#{UUID.uuid4()}"

      :ok = create_persistent_subscription(server, name, stream_id)
      {:ok, subscription} = connect_to_persistent_subscription(server, name, stream_id)

      for event_number <- 1..3 do
        assert_receive {:on_event, %Extreme.Msg.ResolvedIndexedEvent{} = event, correlation_id}

        %Extreme.Msg.ResolvedIndexedEvent{
          event: %Extreme.Msg.EventRecord{
            event_id: event_id,
            event_type: event_type,
            data: data
          }
        } = event

        assert Jason.decode!(data) == %{"event" => event_number}
        assert event_type == "test-event"

        :ok = Extreme.PersistentSubscription.ack(subscription, event_id, correlation_id)
      end

      refute_receive {:on_event, _event, _correlation_id}
    end
  end

  describe "soft delete a stream" do
    setup [:write_events, :soft_delete_stream]

    test "cannot be read", %{server: server, stream_id: stream_id} do
      assert {:error, :NoStream, %ExMsg.ReadStreamEventsCompleted{}} =
               read_events(server, stream_id)
    end

    test "persistent subscription should not receive any events",
         %{server: server, stream_id: stream_id} do
      name = "test-subscription-#{UUID.uuid4()}"

      :ok = create_persistent_subscription(server, name, stream_id)
      {:ok, _subscription} = connect_to_persistent_subscription(server, name, stream_id)

      refute_receive {:on_event, _event, _correlation_id}
    end
  end

  defp write_events(context) do
    %{server: server} = context

    stream_id = UUID.uuid4()

    :ok = write_events(server, stream_id)

    [stream_id: stream_id]
  end

  defp soft_delete_stream(context) do
    %{server: server, stream_id: stream_id} = context

    soft_delete_stream(server, stream_id, 2)
  end

  defp write_events(server, stream_id, expected_version \\ -1) do
    events =
      Enum.map(1..3, fn event_number ->
        ExMsg.NewEvent.new(
          event_id: UUID.uuid4() |> UUID.string_to_binary!(),
          event_type: "test-event",
          data_content_type: 0,
          metadata_content_type: 0,
          data: Jason.encode!(%{"event" => event_number}),
          metadata: "{}"
        )
      end)

    message =
      ExMsg.WriteEvents.new(
        event_stream_id: stream_id,
        expected_version: expected_version,
        events: events,
        require_master: false
      )

    execute(server, message)
  end

  defp read_events(server, stream_id, from_event_number \\ 0, max_count \\ 1_000) do
    message =
      ExMsg.ReadStreamEvents.new(
        event_stream_id: stream_id,
        from_event_number: from_event_number,
        max_count: max_count,
        resolve_link_tos: true,
        require_master: false
      )

    with {:ok, %ExMsg.ReadStreamEventsCompleted{events: events}} <-
           Extreme.execute(server, message) do
      {:ok, events}
    end
  end

  defp soft_delete_stream(server, stream_id, expected_version) do
    message =
      ExMsg.DeleteStream.new(
        event_stream_id: stream_id,
        expected_version: expected_version,
        require_master: false,
        hard_delete: false
      )

    execute(server, message)
  end

  defp create_persistent_subscription(server, name, stream_id, start_from \\ 0) do
    message =
      ExMsg.CreatePersistentSubscription.new(
        subscription_group_name: name,
        event_stream_id: stream_id,
        resolve_link_tos: true,
        start_from: start_from,
        message_timeout_milliseconds: 10_000,
        record_statistics: false,
        live_buffer_size: 500,
        read_batch_size: 20,
        buffer_size: 500,
        max_retry_count: 10,
        prefer_round_robin: false,
        checkpoint_after_time: 1_000,
        checkpoint_max_count: 500,
        checkpoint_min_count: 1,
        subscriber_max_count: 1
      )

    with {:ok, %ExMsg.CreatePersistentSubscriptionCompleted{result: :Success}} <-
           Extreme.execute(server, message) do
      :ok
    end
  end

  defp connect_to_persistent_subscription(server, name, stream) do
    Extreme.connect_to_persistent_subscription(server, self(), name, stream, 1)
  end

  defp execute(server, message) do
    with {:ok, _response} <- Extreme.execute(server, message) do
      :ok
    end
  end

  def config do
    [
      db_type: :node,
      host: "localhost",
      port: 1113,
      username: "admin",
      password: "changeit",
      reconnect_delay: 2_000,
      max_attempts: :infinity
    ]
  end
end
