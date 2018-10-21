defmodule Commanded.EventStore.Adapters.Extreme do
  @moduledoc """
  Adapter to use Greg Young's [Event Store](https://eventstore.org/), via the
  Extreme TCP client, with Commanded.
  """

  @behaviour Commanded.EventStore

  require Logger

  alias Commanded.EventStore.{EventData, RecordedEvent, SnapshotData, TypeProvider}

  alias Commanded.EventStore.Adapters.Extreme.{
    Config,
    Mapper,
    PubSub,
    Subscription,
    SubscriptionsSupervisor
  }

  alias Extreme.Msg, as: ExMsg

  @event_store Commanded.EventStore.Adapters.Extreme.EventStore

  @impl Commanded.EventStore
  def child_spec do
    [
      Commanded.EventStore.Adapters.Extreme.Supervisor
    ]
  end

  @impl Commanded.EventStore
  def append_to_stream(stream_uuid, expected_version, events) do
    stream = stream_name(stream_uuid)

    Logger.debug(fn ->
      "Extreme event store attempting to append to stream " <>
        inspect(stream) <> " " <> inspect(length(events)) <> " event(s)"
    end)

    add_to_stream(stream, expected_version, events)
  end

  @impl Commanded.EventStore
  def stream_forward(stream_uuid, start_version \\ 0, read_batch_size \\ 1_000)

  def stream_forward(stream_uuid, start_version, read_batch_size) do
    stream = stream_name(stream_uuid)
    start_version = normalize_start_version(start_version)

    case execute_read(stream, start_version, read_batch_size, :forward) do
      {:error, reason} ->
        {:error, reason}

      {:ok, events, true} ->
        events

      {:ok, events, false} ->
        Stream.concat(
          events,
          execute_stream_forward(stream, start_version + length(events), read_batch_size)
        )
    end
  end

  @impl Commanded.EventStore
  def subscribe(stream_uuid)

  def subscribe(:all), do: subscribe("$all")

  def subscribe(stream_uuid) do
    with {:ok, _} <- Registry.register(PubSub, stream_uuid, []) do
      :ok
    else
      reply -> reply
    end
  end

  @impl Commanded.EventStore
  def subscribe_to(stream_uuid, subscription_name, subscriber, start_from \\ :origin)

  def subscribe_to(:all, subscription_name, subscriber, start_from) do
    stream = Config.all_stream()

    SubscriptionsSupervisor.start_subscription(stream, subscription_name, subscriber, start_from)
  end

  def subscribe_to(stream_uuid, subscription_name, subscriber, start_from) do
    stream = stream_name(stream_uuid)

    SubscriptionsSupervisor.start_subscription(stream, subscription_name, subscriber, start_from)
  end

  @impl Commanded.EventStore
  def ack_event(subscription, %RecordedEvent{event_number: event_number}) do
    Subscription.ack(subscription, event_number)
  end

  @impl Commanded.EventStore
  def unsubscribe(subscription) do
    SubscriptionsSupervisor.stop_subscription(subscription)
  end

  @impl Commanded.EventStore
  def read_snapshot(source_uuid) do
    stream = snapshot_stream(source_uuid)

    Logger.debug(fn -> "Extreme event store read snapshot from stream: " <> inspect(stream) end)

    case execute_read(stream, -1, 1, :backward) do
      {:ok, [recorded_event], _end_of_stream?} ->
        {:ok, to_snapshot_data(recorded_event)}

      {:error, :stream_not_found} ->
        {:error, :snapshot_not_found}

      err ->
        Logger.error(fn -> "Extreme event store error reading snapshot: " <> inspect(err) end)
        err
    end
  end

  @impl Commanded.EventStore
  def record_snapshot(%SnapshotData{} = snapshot) do
    event_data = to_event_data(snapshot)
    stream = snapshot_stream(snapshot.source_uuid)

    Logger.debug(fn -> "Extreme event store record snapshot to stream: " <> inspect(stream) end)

    case add_to_stream(stream, :any_version, [event_data]) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl Commanded.EventStore
  def delete_snapshot(source_uuid) do
    stream = snapshot_stream(source_uuid)

    case Extreme.execute(@event_store, delete_stream_msg(stream, false)) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def delete_stream(source_uuid) do
    stream = stream_name(source_uuid)

    case Extreme.execute(@event_store, delete_stream_msg(stream, false)) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp execute_stream_forward(stream, start_version, read_batch_size) do
    Stream.resource(
      fn -> {start_version, false} end,
      fn {next_version, halt?} = acc ->
        case halt? do
          true ->
            {:halt, acc}

          false ->
            case execute_read(stream, next_version, read_batch_size, :forward) do
              {:ok, events, end_of_stream?} ->
                acc = {next_version + length(events), end_of_stream?}

                {events, acc}
            end
        end
      end,
      fn _ -> :ok end
    )
  end

  defp prefix(suffix), do: Config.stream_prefix() <> "-" <> suffix

  defp snapshot_stream(source_uuid), do: Config.stream_prefix() <> "snapshot-" <> source_uuid

  defp stream_name(stream), do: prefix(stream)

  defp normalize_start_version(0), do: 0
  defp normalize_start_version(start_version), do: start_version - 1

  defp to_snapshot_data(%RecordedEvent{data: snapshot} = event) do
    data =
      snapshot.source_type
      |> String.to_existing_atom()
      |> struct(with_atom_keys(snapshot.data))
      |> Commanded.Serialization.JsonDecoder.decode()

    %SnapshotData{snapshot | data: data, created_at: event.created_at}
  end

  defp with_atom_keys(map) do
    Enum.reduce(Map.keys(map), %{}, fn key, m ->
      Map.put(m, String.to_existing_atom(key), Map.get(map, key))
    end)
  end

  defp to_event_data(%SnapshotData{} = snapshot) do
    %EventData{
      event_type: TypeProvider.to_string(snapshot),
      data: snapshot
    }
  end

  defp add_to_stream(stream, :stream_exists, events) do
    case execute_read(stream, 0, 1, :forward) do
      {:ok, _events, _end_of_stream?} ->
        add_to_stream(stream, :any_version, events)

      {:error, :stream_not_found} ->
        {:error, :stream_does_not_exist}

      {:error, _error} = reply ->
        reply
    end
  end

  defp add_to_stream(stream, expected_version, events) do
    msg = write_events(stream, expected_version, events)

    case Extreme.execute(@event_store, msg) do
      {:ok, _response} ->
        :ok

      {:error, :WrongExpectedVersion, detail} ->
        Logger.warn(fn ->
          "Extreme event store wrong expected version " <>
            inspect(expected_version) <> " due to: " <> inspect(detail)
        end)

        case expected_version do
          :no_stream -> {:error, :stream_exists}
          :stream_exists -> {:error, :stream_does_not_exist}
          _ -> {:error, :wrong_expected_version}
        end

      reply ->
        reply
    end
  end

  defp delete_stream_msg(stream, hard_delete) do
    ExMsg.DeleteStream.new(
      event_stream_id: stream,
      expected_version: -2,
      require_master: false,
      hard_delete: hard_delete
    )
  end

  defp execute_read(stream, start_version, count, direction, read_events \\ []) do
    remaining_count = count - length(read_events)
    read_request = read_events(stream, start_version, remaining_count, direction)

    case Extreme.execute(@event_store, read_request) do
      {:ok, %ExMsg.ReadStreamEventsCompleted{} = result} ->
        %ExMsg.ReadStreamEventsCompleted{
          is_end_of_stream: end_of_stream?,
          events: events
        } = result

        read_events = read_events ++ events

        if end_of_stream? || length(read_events) == count do
          recorded_events = Enum.map(read_events, &Mapper.to_recorded_event/1)

          {:ok, recorded_events, end_of_stream?}
        else
          # can occur with soft deleted streams
          start_version =
            case direction do
              :forward -> result.next_event_number
              :backward -> result.last_event_number
            end

          execute_read(stream, start_version, remaining_count, direction, read_events)
        end

      {:error, :NoStream, _} ->
        {:error, :stream_not_found}

      err ->
        err
    end
  end

  defp read_events(stream, from_event_number, max_count, direction) do
    msg_type =
      if :forward == direction, do: ExMsg.ReadStreamEvents, else: ExMsg.ReadStreamEventsBackward

    msg_type.new(
      event_stream_id: stream,
      from_event_number: from_event_number,
      max_count: max_count,
      resolve_link_tos: true,
      require_master: false
    )
  end

  defp add_causation_id(metadata, causation_id),
    do: add_to_metadata(metadata, "$causationId", causation_id)

  defp add_correlation_id(metadata, correlation_id),
    do: add_to_metadata(metadata, "$correlationId", correlation_id)

  defp add_to_metadata(metadata, key, value) when is_nil(metadata),
    do: add_to_metadata(%{}, key, value)

  defp add_to_metadata(metadata, _key, value) when is_nil(value), do: metadata

  defp add_to_metadata(metadata, key, value), do: Map.put(metadata, key, value)

  defp write_events(stream_id, expected_version, events) do
    expected_version = expected_version(expected_version)

    proto_events =
      Enum.map(events, fn event ->
        metadata =
          event.metadata
          |> add_causation_id(event.causation_id)
          |> add_correlation_id(event.correlation_id)

        ExMsg.NewEvent.new(
          event_id: UUID.uuid4() |> UUID.string_to_binary!(),
          event_type: event.event_type,
          data_content_type: 0,
          metadata_content_type: 0,
          data: serialize(event.data),
          metadata: serialize(metadata)
        )
      end)

    ExMsg.WriteEvents.new(
      event_stream_id: stream_id,
      expected_version: expected_version,
      events: proto_events,
      require_master: false
    )
  end

  def serialize(data), do: Config.serializer().serialize(data)

  # Event store supports the following special values for expected version:
  #
  #  -2 states that this write should never conflict and should always succeed.
  #  -1 states that the stream should not exist at the time of the writing.
  #  0 states that the stream should exist but should be empty.
  #
  #  Any other integer value represents the version of the stream you expect.
  #
  defp expected_version(:any_version), do: -2
  defp expected_version(:no_stream), do: -1
  defp expected_version(:stream_exists), do: 0
  defp expected_version(expected_version), do: expected_version - 1
end
