defmodule Commanded.EventStore.Adapters.Extreme.SubscriptionsSupervisor do
  use Supervisor
  require Logger

  alias Commanded.EventStore.Adapters.Extreme.Subscription

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_subscription(stream, subscription_name, subscriber, start_from) do
    Supervisor.start_child(
      __MODULE__,
      subscription_spec(stream, subscription_name, subscriber, start_from)
    )
    |> case  do
      {:error, :already_present} -> Supervisor.restart_child(__MODULE__, subscription_name)
      other -> other
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
      restart: :transient,
    )
  end
end
