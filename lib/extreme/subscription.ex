defmodule Commanded.EventStore.Adapters.Extreme.Subscription do
  use GenServer

  require Logger

  alias Extreme.Msg, as: ExMsg

  @event_store Commanded.EventStore.Adapters.Extreme.EventStore

  defmodule State do
    defstruct [
      stream: nil,
      name: nil,
      start_from: nil,
      subscriber: nil,
      subscriber_ref: nil,
      subscription: nil,
      subscription_ref: nil,
      subscribed?: false,
      result: nil,
      last_seen_correlation_id: nil,
      last_seen_event_id: nil,
      last_seen_event_number: nil,
    ]
  end

  alias Commanded.EventStore.Adapters.Extreme, as: ExtremeAdapter
  alias Commanded.EventStore.Adapters.Extreme.Subscription.State

  @doc """
  Start a process to create and connect a persistent connection to the Event Store
  """
  def start(stream, subscription_name, subscriber, start_from) do
    GenServer.start(__MODULE__, %State{
      stream: stream,
      name: subscription_name,
      subscriber: subscriber,
      start_from: start_from,
    })
  end

  @doc """
  Acknowledge receipt and successful processing of the given event
  """
  def ack(subscription, event_number) do
    GenServer.cast(subscription, {:ack, event_number})
  end

  def init(%State{subscriber: subscriber} = state) do
    state = %State{state |
      subscriber_ref: Process.monitor(subscriber),
    }

    GenServer.cast(self(), {:subscribe})

    {:ok, state}
  end

  def result(subscription) do
    GenServer.call(subscription, :result)
  end

  def handle_cast({:subscribe}, state) do
    Logger.debug(fn -> "Extreme event store subscribe to stream: #{inspect state.stream}, start from: #{inspect state.start_from}" end)

    {:noreply, subscribe(state)}
  end

  def handle_cast({:ack, event_number}, %State{subscription: subscription, last_seen_correlation_id: correlation_id, last_seen_event_id: event_id, last_seen_event_number: event_number} = state) do
    Logger.debug(fn -> "Extreme event store ack event: #{inspect event_number}" end)

    :ok = Extreme.PersistentSubscription.ack(subscription, event_id, correlation_id)

    state = %State{state |
      last_seen_event_id: nil,
      last_seen_event_number: nil,
    }

    {:noreply, state}
  end

  def handle_call(:result, _from, %State{result: result} = state) do
    {:reply, result, state}
  end

  def handle_info({:on_event, event, correlation_id}, %State{subscriber: subscriber, subscription: subscription} = state) do
    Logger.debug(fn -> "Extreme event store subscription received event: #{inspect event}" end)

    event_type = event.event.event_type

    state = if "$" != String.first(event_type) do
      recorded_event = ExtremeAdapter.to_recorded_event(event)

      send(subscriber, {:events, [recorded_event]})

      %State{state |
        last_seen_correlation_id: correlation_id,
        last_seen_event_id: event.link.event_id,
        last_seen_event_number: recorded_event.event_number,
      }
    else
      Logger.debug(fn -> "Extreme event store subscription ignoring event of type: #{inspect event_type}" end)

      :ok = Extreme.PersistentSubscription.ack(subscription, event.link.event_id, correlation_id)

      state
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %State{subscriber_ref: subscriber_ref, subscription_ref: subscription_ref} = state) do
    Logger.debug(fn -> "Extreme event store subscription down due to: #{inspect reason}" end)

    case {ref, reason} do
      {^subscriber_ref, _} ->
        {:stop, {:shutdown, :subscriber_shutdown}, state}

      {^subscription_ref, :unsubscribe} ->
        {:noreply, state}

      {^subscription_ref, _} ->
        {:stop, {:shutdown, :receiver_shutdown}, state}
    end
  end

  defp subscribe(%State{} = state) do
    with :ok <- create_persistent_subscription(state),
         {:ok, subscription} <- connect_to_persistent_subscription(state) do
      %State{state |
        result: {:ok, self()},
        subscription: subscription,
        subscription_ref: Process.monitor(subscription),
        subscribed?: true,
      }
    else
      err ->
        %State{state |
          result: err,
          subscribed?: false,
        }
    end
  end

  defp create_persistent_subscription(%State{name: name, stream: stream, start_from: start_from}) do
    from_event_number =
      case start_from do
      	:origin -> 0
      	:current -> -1
      	event_number -> event_number
      end

    message = ExMsg.CreatePersistentSubscription.new(
      subscription_group_name: name,
      event_stream_id: stream,
      resolve_link_tos: true,
      start_from: from_event_number,
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

    case Extreme.execute(@event_store, message) do
      {:ok, %ExMsg.CreatePersistentSubscriptionCompleted{result: :Success}} -> :ok
      {:error, :AlreadyExists, _response} -> :ok
      error -> error
    end
  end

  defp connect_to_persistent_subscription(%State{name: name, stream: stream}) do
    Extreme.connect_to_persistent_subscription(@event_store, self(), name, stream, 1)
  end

  defp unsubscribe(%State{} = state) do
    state
    # if state.receiver do
    #   Process.exit(state.receiver, :unsubscribe)
    #
    #   %State{state | receiver: nil}
    # else
    #   state
    # end
  end
end
