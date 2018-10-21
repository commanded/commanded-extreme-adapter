defmodule Commanded.EventStore.Adapters.Extreme.EventPublisher do
  use Extreme.FanoutListener

  alias Commanded.EventStore.Adapters.Extreme.{Mapper, PubSub}
  alias Commanded.EventStore.RecordedEvent

  defp process_push(push) do
    push
    |> Mapper.to_recorded_event()
    |> publish()
  end

  defp publish(%RecordedEvent{} = recorded_event) do
    :ok = publish_to_all(recorded_event)
    :ok = publish_to_stream(recorded_event)
  end

  defp publish_to_all(%RecordedEvent{} = recorded_event) do
    Registry.dispatch(PubSub, "$all", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:events, [recorded_event]})
    end)
  end

  defp publish_to_stream(%RecordedEvent{} = recorded_event) do
    %RecordedEvent{stream_id: stream_id} = recorded_event

    Registry.dispatch(PubSub, stream_id, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:events, [recorded_event]})
    end)
  end
end
