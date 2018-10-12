defmodule Commanded.EventStore.Adapters.Extreme.AppendEventsTest do
  use Commanded.EventStore.AppendEventsTestCase

  alias Commanded.EventStore.Adapters.Extreme.Storage

  setup do
    on_exit(fn ->
      Storage.reset!()
    end)

    :ok
  end
end
