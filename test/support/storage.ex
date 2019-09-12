defmodule Commanded.EventStore.Adapters.Extreme.Storage do
  def wait_for_event_store do
    headers = [Accept: "application/vnd.eventstore.atom+json"]
    options = [recv_timeout: 400]

    case HTTPoison.get("http://localhost:2113/streams/somestream", headers, options) do
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :timer.sleep(1_000)

        :ok

      _ ->
        :timer.sleep(1_000)

        wait_for_event_store()
    end
  end
end
