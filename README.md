# Extreme event store adapter for Commanded

Use Greg Young's [Event Store](https://geteventstore.com/) with [Commanded](https://github.com/commanded/commanded) using the [Extreme](https://github.com/exponentially/extreme) Elixir TCP client.

---

[Changelog](CHANGELOG.md)

MIT License

[![Build Status](https://travis-ci.com/commanded/commanded-extreme-adapter.svg?branch=master)](https://travis-ci.com/commanded/commanded-extreme-adapter)

---

### Overview

- [Getting started](#getting-started)
- [Testing](#testing)
- [Contributing](#contributing)

---

## Getting started

The package can be installed from hex as follows.

1. Add `commanded_extreme_adapter` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:commanded_extreme_adapter, "~> 0.6"}]
    end
    ```

2. Configure Commanded to use the event store adapter:

    ```elixir
    config :commanded, event_store_adapter: Commanded.EventStore.Adapters.Extreme
    ```

3. Configure the `extreme` library connection with your Event Store connection details:

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

4. Configure the `commanded_extreme_adapter` to specify the JSON serializer and a stream prefix to be used by all Commanded event streams:

    ```elixir
    config :commanded_extreme_adapter,
      serializer: Commanded.Serialization.JsonSerializer,
      stream_prefix: "commandeddev"
    ```

    **Note** Stream prefix *must not* contain a dash character ("-").

You **must** run the Event Store with all projections enabled and standard projections started. Use the `--run-projections=all --start-standard-projections=true` flags when running the Event Store executable.

## Testing

The test suite uses Docker to run the official [Event Store](https://store.docker.com/community/images/eventstore/eventstore) container. You must pull the docker image and start the container *before* running the test suite.

### Getting started

Pull the docker image:

```
docker pull eventstore/eventstore
```

Run the container using:

```
docker run --name eventstore -it -p 2113:2113 -p 1113:1113 \
  -e EVENTSTORE_START_STANDARD_PROJECTIONS=True \
  -e EVENTSTORE_RUN_PROJECTIONS=all \
  eventstore/eventstore
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

## Contributing

Pull requests to contribute new or improved features, and extend documentation are most welcome.

Please follow the existing coding conventions, or refer to the [Elixir style guide](https://github.com/niftyn8/elixir_style_guide).

You should include unit tests to cover any changes. Run `mix test` to execute the test suite.

### Contributors

- [Ben Smith](https://github.com/slashdotdash)
- [Jan Fornoff](https://github.com/jfornoff)
- [Tim Buchwaldt](https://github.com/timbuchwaldt)
