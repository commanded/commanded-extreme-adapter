defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionsSupervisor do
  use Supervisor
  require Logger

  alias Commanded.EventStore.Adapters.Extreme.Subscription

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_subscription(stream, subscription_name, subscriber, start_from) do
    spec = subscription_spec(stream, subscription_name, subscriber, start_from)

    case Supervisor.start_child(__MODULE__, spec) do
      {:error, :already_present} ->
        :ok = Supervisor.delete_child(__MODULE__, subscription_name)
        
        Supervisor.start_child(__MODULE__, spec)

      other ->
        other
    end
  end

  def stop_subscription(subscription_name) do
    Supervisor.terminate_child(__MODULE__, subscription_name)
  end

  defp subscription_spec(stream, subscription_name, subscriber, start_from) do
    Supervisor.Spec.worker(
      Subscription,
      [stream, subscription_name, subscriber, start_from],
      id: subscription_name,
      restart: :transient
    )
  end
end
