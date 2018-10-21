defmodule Commanded.EventStore.Adapters.Extreme.StorageCase do
  use ExUnit.CaseTemplate

  setup do
    Commanded.EventStore.Adapters.Extreme.Storage.reset()
  end
end
