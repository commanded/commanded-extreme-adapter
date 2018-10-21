defmodule Commanded.EventStore.Adapters.Extreme.Mapper do
  alias Commanded.EventStore.Adapters.Extreme.Config
  alias Commanded.EventStore.RecordedEvent
  alias Extreme.Msg, as: ExMsg

  def to_recorded_event(%ExMsg.ResolvedIndexedEvent{event: event, link: nil}),
    do: to_recorded_event(event, event.event_number + 1)

  def to_recorded_event(%ExMsg.ResolvedIndexedEvent{event: event, link: link}),
    do: to_recorded_event(event, link.event_number + 1)

  def to_recorded_event(%ExMsg.ResolvedEvent{event: event, link: nil}),
    do: to_recorded_event(event, event.event_number + 1)

  def to_recorded_event(%ExMsg.ResolvedEvent{event: event, link: link}),
    do: to_recorded_event(event, link.event_number + 1)

  def to_recorded_event(%ExMsg.EventRecord{} = event),
    do: to_recorded_event(event, event.event_number + 1)

  def to_recorded_event(%ExMsg.EventRecord{} = event, event_number) do
    %ExMsg.EventRecord{
      event_id: event_id,
      event_type: event_type,
      event_number: stream_version,
      created_epoch: created_epoch,
      data: data,
      metadata: metadata
    } = event

    data = deserialize(data, type: event_type)

    metadata =
      case metadata do
        none when none in [nil, ""] -> %{}
        metadata -> deserialize(metadata)
      end

    {causation_id, metadata} = Map.pop(metadata, "$causationId")
    {correlation_id, metadata} = Map.pop(metadata, "$correlationId")

    %RecordedEvent{
      event_id: UUID.binary_to_string!(event_id),
      event_number: event_number,
      stream_id: to_stream_id(event),
      stream_version: stream_version + 1,
      causation_id: causation_id,
      correlation_id: correlation_id,
      event_type: event_type,
      data: data,
      metadata: metadata,
      created_at: to_naive_date_time(created_epoch)
    }
  end

  defp deserialize(data, opts \\ []),
    do: Config.serializer().deserialize(data, opts)

  defp to_stream_id(%ExMsg.EventRecord{event_stream_id: event_stream_id}) do
    event_stream_id
    |> String.split("-")
    |> Enum.drop(1)
    |> Enum.join("-")
  end

  defp to_naive_date_time(millis_since_epoch) do
    secs_since_epoch = round(Float.floor(millis_since_epoch / 1000))
    millis = :erlang.rem(millis_since_epoch, 1000)
    epoch_secs = :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
    erl_date = :calendar.gregorian_seconds_to_datetime(epoch_secs + secs_since_epoch)

    NaiveDateTime.from_erl!(erl_date, {millis * 1000, 3})
  end
end
