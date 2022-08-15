# Redis

[Redis](https://redis.io/) is one of the most popular in-memory data structure store commonly used as a cache or message broker.

This library is an integration between Vapor and [**RediStack**](https://gitlab.com/mordil/redistack), which is the underlying driver that communicates with Redis.

!!! note
    Most of the capabilities of Redis are provided by **RediStack**.
    We highly recommend being familiar with its documentation.
    
    _Links are provided where appropriate._

## Package

The first step to using Redis is adding it as a dependency to your project in your Swift package manifest.

> This example is for an existing package. For help on starting a new project, see the main [Getting Started](../getting-started/hello-world.md) guide.

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/vapor/redis.git", from: "4.0.0")
]
// ...
targets: [
    .target(name: "App", dependencies: [
        // ...
        .product(name: "Redis", package: "redis")
    ])
]
```

## Configure

Vapor employs a pooling strategy for [`RedisConnection`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redisconnection) instances, and there are several options to configure individual connections as well as the pools themselves.

The bare minimum required for configuring Redis is to provide a URL to connect to:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redis Configuration

> API Documentation: [`RedisConfiguration`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/)

#### serverAddresses

If you have multiple Redis endpoints, such as a cluster of Redis instances, you'll want to create a [`[SocketAddress]`](https://apple.github.io/swift-nio/docs/current/NIOCore/Enums/SocketAddress.html#/s:3NIO13SocketAddressO04makeC13ResolvingHost_4portACSS_SitKFZ) collection to pass in the initializer instead.

The most common way of creating a `SocketAddress` is with the [`makeAddressResolvingHost(_:port:)`](https://apple.github.io/swift-nio/docs/current/NIOCore/Enums/SocketAddress.html#/s:3NIO13SocketAddressO04makeC13ResolvingHost_4portACSS_SitKFZ) static method.

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

For a single Redis endpoint, it can be easier to work with the convenience initializers, as it will handle creating the `SocketAddress` for you:

- [`.init(url:pool)`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/#redisconfiguration.init(url:pool:)) (with `String` or [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/#redisconfiguration.init(hostname:port:password:database:pool:))

#### password

If your Redis instance is secured by a password, you will need to pass it as the `password` argument.

Each connection, as it is created, will be authenticated using the password.

#### database

This is the database index you wish to select when each connection is created.

This saves you from having to send the `SELECT` command to Redis yourself.

!!! warning
    The database selection is not maintained. Be careful with sending the `SELECT` command on your own.

### Connection Pool Options

> API Documentation: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration_PoolOptions/)

!!! note
    Only the most commonly changed options are highlighted here. For all of the options, refer to the API documentation.

#### minimumConnectionCount

This is the value to set how many connections you want each pool to maintain at all times.

If you value is `0` then if connections are lost for any reason, the pool will not recreate them until needed.

This is known as a "cold start" connection, and does have some overhead over maintaining a minimum connection count.

#### maximumConnectionCount

This option determines the behavior of how the maximum connection count is maintained.

!!! seealso
    Refer to the `RedisConnectionPoolSize` API to be familiar with what options are available.

## Sending a Command

You can send commands using the `.redis` property on any [`Application`](https://api.vapor.codes/vapor/main/Vapor/Application/) or [`Request`](https://api.vapor.codes/vapor/main/Vapor/Request/) instance, which will give you access to a [`RedisClient`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redisclient).

Any `RedisClient` has several extensions for all of the various [Redis commands](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Unsupported Commands

Should **RediStack** not support a command with an extension method, you can still send it manually.

```swift
// each value after the command is the positional argument that Redis expects
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// or

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Pub/Sub Mode

Redis supports the ability to enter a ["Pub/Sub" mode](https://redis.io/topics/pubsub) where a connection can listen to specific "channels" and run specific closures when the subscribed channels publish a "message" (some data value).

There is a defined lifecycle to a subscription:

1. **subscribe**: invoked once when the subscription first starts
1. **message**: invoked 0+ times as messages are published to the subscribed channels
1. **unsubscribe**: invoked once when the subscription ends, either by request or the connection being lost

When you create a subscription, you must provide at least a [`messageReceiver`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redissubscriptionmessagereceiver) to handle all messages that are published by the subscribed channel.

You can optionally provide a `RedisSubscriptionChangeHandler` for `onSubscribe` and `onUnsubscribe` to handle their respective lifecycle events.

```swift
// creates 2 subscriptions, one for each given channel
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // do something with the message
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
