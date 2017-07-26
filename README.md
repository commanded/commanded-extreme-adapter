# Extreme event store adapter for Commanded

Use Greg Young's [Event Store](https://geteventstore.com/) with [Commanded](https://github.com/slashdotdash/commanded) using the [Extreme](https://github.com/exponentially/extreme) Elixir TCP client.

---

[Changelog](CHANGELOG.md)

MIT License

[![Build Status](https://travis-ci.org/slashdotdash/commanded-extreme-adapter.svg?branch=master)](https://travis-ci.org/slashdotdash/commanded-extreme-adapter)

---

## Getting started

The package can be installed from hex as follows.

1. Add `commanded_extreme_adapter` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:commanded_extreme_adapter, "~> 0.1"}]
    end
    ```

2. Configure Commanded to use the event store adapter:

    ```elixir
    config :commanded,
      event_store_adapter: Commanded.EventStore.Adapters.Extreme
    ```

3. Configure the `extreme` library connection with your event store connection details:

    ```elixir
    config :extreme, :event_store,
      db_type: :node,
      host: "localhost",
      port: 1113,
      username: "admin",
      password: "changeit",
      reconnect_delay: 2_000,
      max_attempts: :infinity
    ```

4. Configure the `commanded_extreme_adapter` to specify a stream prefix to be used by all Commanded event streams:

    ```elixir
    config :commanded_extreme_adapter,
      stream_prefix: "commandeddev"
    ```

    **Note** Stream prefix *must not* contain a dash character ("-").

5. Force a (re)compile of the Commanded dependency to include the configured adapter:

    ```console
    $ mix deps.compile commanded --force
    ```

You **must** run the Event Store with all projections enabled and standard projections started. Use the `--run-projections=all --start-standard-projections=true` flags when running the Event Store executable.

## Testing

The test suite uses Docker to run the official [Event Store](https://store.docker.com/community/images/eventstore/eventstore) container.

You will need to install Docker. For Mac uses, you may also need to install `socat` to expose the Docker API via a TCP port from its default Unix socket.

```
socat TCP-LISTEN:2375,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock
```

### Getting started

Pull the docker image:

```
docker pull eventstore/eventstore
```

Run the container using:

```
docker run --name eventstore-node -it -p 2113:2113 -p 1113:1113 eventstore/eventstore
```

Note: The admin UI and atom feeds will only work if you publish the node's http port to a matching port on the host. (i.e. you need to run the container with -p 2113:2113).

### Web UI

Get the docker ip address:

```
docker-machine ip default
```

Using the ip address and the external http port (defaults to 2113) you can use the browser to view the event store admin UI.

e.g. http://localhost:2113/

Username and password is `admin` and `changeit` respectively.
