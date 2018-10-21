defmodule Commanded.EventStore.Adapters.Extreme.EventPublisher do
  use Extreme.FanoutListener

  alias Commanded.EventStore.Adapters.Extreme, as: ExtremeAdapter
  alias Commanded.EventStore.Adapters.Extreme.PubSub
  alias Commanded.EventStore.RecordedEvent

  defp process_push(push) do
    push
    |> ExtremeAdapter.to_recorded_event()
    |> publish()
  end

  defp publish(%RecordedEvent{stream_id: stream_id} = recorded_event) do
    Registry.dispatch(PubSub, :all, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:events, [recorded_event]})
    end)

    Registry.dispatch(PubSub, stream_id, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:events, [recorded_event]})
    end)
  end
end
