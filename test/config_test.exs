defmodule Commanded.EventStore.Adapters.Extreme.ConfigTest do
	use ExUnit.Case

  alias Commanded.EventStore.Adapters.Extreme.Config

  setup do
    stream_prefix = Application.get_env(:commanded_extreme_adapter, :stream_prefix)

    on_exit(fn ->
      Application.put_env(:commanded_extreme_adapter, :stream_prefix, stream_prefix)
    end)
  end

  test "should raise error when stream prefix contains \"-\"" do
    Application.put_env(:commanded_extreme_adapter, :stream_prefix, "invalid-prefix")

    assert_raise ArgumentError, ":stream_prefix cannot contain a dash (\"-\")", fn ->
      Config.stream_prefix()
    end
  end
end
