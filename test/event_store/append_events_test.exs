defmodule Commanded.EventStore.Adapters.Extreme.AppendEventsTest do
  use Commanded.EventStore.AppendEventsTestCase

  alias Commanded.EventStore.Adapters.Extreme.Storage

  setup do
    Storage.reset!()
  end
end
