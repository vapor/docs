# Custom commands

Many commands are not (yet) implemented by the driver using a convenience function. This does not mean the feature/command is not usable.

[(Almost) all functions listed here](https://redis.io/commands) work out of the box using custom commands.

## Usage

The Redis client has a `run` function that allows you to run these commands.

The following code demonstrates a "custom" implementation for [GET](https://redis.io/commands/get).

```swift
let future = client.run(command: "GET", arguments: ["my-key"]) // Future<RedisData>
```

This future will contain the result as specified in the article on the redis command page or an error.
