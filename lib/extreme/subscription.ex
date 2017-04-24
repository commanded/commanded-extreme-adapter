defmodule Commanded.EventStore.Adapters.Extreme.Subscription do
  use GenServer

  require Logger

  @event_store Commanded.EventStore.Adapters.Extreme.EventStore
  @max_buffer_size 1_000

  defmodule State do
    defstruct [
      stream: nil,
      name: nil,
      subscriber: nil,
      subscriber_ref: nil,
      start_from: nil,
      result: nil,
      receiver: nil,
      receiver_ref: nil,
      last_rcvd_event_no: nil,
      events_buffer: [],
      inflight_events: [],
      events_total: 0,
      max_buffer_size: nil,
    ]
  end

  alias Commanded.EventStore.Adapters.Extreme, as: ExtremeAdapter
  alias Commanded.EventStore.Adapters.Extreme.Subscription.State

  def start(stream, subscription_name, subscriber, start_from, opts \\ []) do
    GenServer.start(__MODULE__, %State{
      stream: stream,
      name: subscription_name,
      subscriber: subscriber,
      subscriber_ref: nil,
      start_from: start_from,
      result: nil,
      receiver: nil,
      receiver_ref: nil,
      last_rcvd_event_no: nil,
      events_buffer: [],
      inflight_events: [],
      events_total: 0,
      max_buffer_size: opts[:max_buffer_size] || @max_buffer_size
    })
  end

  def init(%State{} = state) do
    state = %State{state |
      subscriber_ref: Process.monitor(state.subscriber),
    }

    Logger.debug(fn -> "subscribe to stream: #{state.stream} | start_from: #{state.start_from}" end)

    {:ok, subscribe(state)}
  end

  def result(pid) do
    GenServer.call(pid, :result)
  end

  def handle_call(:result, _from, state) do
    {:reply, state.result, state}
  end

  def handle_info({:ack, last_seen_stream_version}, %State{inflight_events: inflight} = state) do
    inflight_updated = Enum.filter(inflight, &(&1.stream_version > last_seen_stream_version))
    events_acked_count = length(inflight) - length(inflight_updated)

    state = %State{state |
      inflight_events: inflight_updated,
      events_total: state.events_total - events_acked_count,
    }

    can_subscribe = state.receiver == nil && state.events_total < (state.max_buffer_size/2)
    state = if can_subscribe, do: subscribe(state), else: state

    {:noreply, state}
  end

  def handle_info({:on_event, event}, %State{} = state) do
    event_type = event.event.event_type

    state = if "$" != String.first(event_type) do
      state
      |> add_event_to_buffer(event)
      |> process_buffer
    else
      Logger.debug(fn -> "ignoring event of type: #{inspect event_type}" end)
      state
    end

    {:noreply, state}
  end

  def handle_info(:caught_up, %State{} = state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %State{subscriber_ref: subscriber_ref, receiver_ref: receiver_ref} = state) do
    case {ref, reason} do
      {^subscriber_ref, _} -> Process.exit(self(), :subscriber_shutdown)
      {^receiver_ref, :unsubscribe} -> :noop
      {^receiver_ref, _} -> Process.exit(self(), :receiver_shutdown)
    end

    {:noreply, state}
  end

  defp subscribe(%State{} = state) do
    from_event_number =
      case state.start_from do
      	:origin -> 0
      	:current -> nil
      	event_number -> event_number
      end

    receiver = spawn_receiver()

    state = %State{state |
      receiver_ref: Process.monitor(receiver),
    }

    result =
      case from_event_number do
      	nil -> Extreme.subscribe_to(@event_store, receiver, state.stream)
      	event_number -> Extreme.read_and_stay_subscribed(@event_store, receiver, state.stream, event_number)
      end

    case result do
      {:ok, _} -> %State{state | result: {:ok, self()}, receiver: receiver}
      err      -> %State{state | result: err}
    end
  end

  defp spawn_receiver do
    subscription = self()

    Process.spawn(fn ->
      receive_loop = fn(loop) ->
      	receive do
      	  {:on_event, event} -> send(subscription, {:on_event, event})
      	end

        loop.(loop)
      end

      receive_loop.(receive_loop)
    end, [])
  end

  defp unsubscribe(%State{} = state) do
    if state.receiver do
      Process.exit(state.receiver, :unsubscribe)
      %State{state | receiver: nil}
    else
      state
    end
  end

  defp add_event_to_buffer(%State{} = state, ev) do
    if (state.events_total < state.max_buffer_size) do
      %State{state |
      	events_buffer: [ev | state.events_buffer],
      	last_rcvd_event_no: ev.event.event_number,
      	events_total: state.events_total + 1,
      	start_from: ev.event.event_number + 1,
      }
    else
      unsubscribe(state)
    end
  end

  defp process_buffer(%State{events_buffer: events_buffer} = state) do
    case events_buffer do
      []      -> state
      _events -> publish_events(state)
    end
  end

  defp publish_events(%State{subscriber: subscriber, events_buffer: events} = state) do
    inflight =
      events
      |> Enum.reverse()
      |> Enum.map(&ExtremeAdapter.to_recorded_event/1)

    send(subscriber, {:events, inflight})

    %State{state |
      events_buffer: [],
      inflight_events: inflight ++ state.inflight_events,
    }
  end
end
