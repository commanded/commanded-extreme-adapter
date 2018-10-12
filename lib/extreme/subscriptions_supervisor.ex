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

  def start_subscription(stream, subscription_name, subscriber, start_from) do
    spec = subscription_spec(stream, subscription_name, subscriber, start_from)

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        {:ok, pid}

      {:ok, pid, _info} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        {:error, :subscription_already_exists}

      reply ->
        reply
    end
  end

  def stop_subscription(subscription) do
    DynamicSupervisor.terminate_child(__MODULE__, subscription)
  end

  defp subscription_spec(stream, subscription_name, subscriber, start_from) do
    %{
      id: subscription_name,
      start: {Subscription, :start_link, [stream, subscription_name, subscriber, start_from]},
      restart: :temporary,
      shutdown: 5_000,
      type: :worker
    }
  end
end
