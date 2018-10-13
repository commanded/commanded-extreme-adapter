defmodule Commanded.EventStore.Adapters.Extreme.SnapshotTest do
  use Commanded.EventStore.SnapshotTestCase

  alias Commanded.EventStore.Adapters.Extreme.Storage

  setup do
    Storage.reset!()
  end
end
