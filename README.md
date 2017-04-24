# Extreme event store adapter for Commanded

Use Greg Young's [Event Store](https://geteventstore.com/) with [Commanded](https://travis-ci.org/slashdotdash/commanded) using the [Extreme](https://github.com/exponentially/extreme) Elixir TCP client.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `commanded_extreme_adapter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:commanded_extreme_adapter, "~> 0.1.0"}]
end
```

## Testing

The test suite uses Docker to run the official [Event Store](https://store.docker.com/community/images/eventstore/eventstore) container.

You will need to install Docker. For Mac uses, you may also need to install `socat` to expose the Docker API via a TCP port from its default Unix socket.

``
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

Username and password is admin and changeit respectively.
