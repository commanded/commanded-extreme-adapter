defmodule Commanded.EventStore.Adapters.Extreme.SnapshotTest do
  use Commanded.EventStore.SnapshotTestCase

  alias Commanded.EventStore.Adapters.Extreme.Storage

  setup do
    on_exit(fn ->
      Storage.reset!()
    end)

    :ok
  end
end
