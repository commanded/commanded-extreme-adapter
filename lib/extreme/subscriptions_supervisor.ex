defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionsSupervisor do
  use DynamicSupervisor

  require Logger

  alias Commanded.EventStore.Adapters.Extreme.Subscription

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_subscription(stream, subscription_name, subscriber, opts, index \\ 0) do
    spec = subscription_spec(stream, subscription_name, subscriber, opts, index)

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        {:ok, pid}

      {:ok, pid, _info} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        case Keyword.get(opts, :subscriber_max_count) do
          nil ->
            {:error, :subscription_already_exists}

          subscriber_max_count ->
            if index < subscriber_max_count - 1 do
              start_subscription(stream, subscription_name, subscriber, opts, index + 1)
            else
              {:error, :too_many_subscribers}
            end
        end

      reply ->
        reply
    end
  end

  def stop_subscription(subscription) do
    DynamicSupervisor.terminate_child(__MODULE__, subscription)
  end

  defp subscription_spec(stream, subscription_name, subscriber, opts, index) do
    start_args = [
      stream,
      subscription_name,
      subscriber,
      Keyword.put(opts, :index, index)
    ]

    %{
      id: {Subscription, stream, subscription_name, index},
      start: {Subscription, :start_link, start_args},
      restart: :temporary,
      shutdown: 5_000,
      type: :worker
    }
  end
end
