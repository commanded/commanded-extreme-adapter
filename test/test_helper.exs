Code.require_file(
  "../deps/commanded/test/support/shared_test_case.ex",
  __DIR__
)

Code.require_file(
  "../deps/commanded/test/event_store/support/subscriber.ex",
  __DIR__
)

Code.require_file(
  "../deps/commanded/test/event_store/support/snapshot_test_case.ex",
  __DIR__
)

ExUnit.start()

Application.put_env(:commanded, :event_store_adapter, Commanded.EventStore.Adapters.Extreme)
