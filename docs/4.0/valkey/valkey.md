# Valkey

[Valkey](https://valkey.io) is a fork of Redis v7.2.4 with additional features and improvements.
It is backed by the Linux Foundation, ensuring it will remain open source forever.

[`vapor-community/valkey`](https://github.com/vapor-community/valkey) is an integration between Vapor and [**valkey-swift**](https://github.com/valkey-io/valkey-swift), which is the underlying driver that communicates with both Valkey and Redis (up to v7.2.4).

!!! tip
    If you have a Redis database, up to version 7.2.4, you can connect to it using the same `vapor-community/valkey` integration.

!!! note
    All of the capabilities of Valkey and Redis are provided by **valkey-swift**.
    We highly recommend being familiar with its documentation.
    
    _Links are provided where appropriate._

## Package

The first step to using `vapor-community/valkey` is adding it and **valkey-swift** as dependencies to your project in your Swift package manifest.

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/vapor-community/valkey.git", from: "1.2.0"),
    .package(url: "https://github.com/valkey-io/valkey-swift.git", from: "1.0.0"),
],
targets: [
    .target(name: "App", dependencies: [
        // ...
        .product(name: "VaporValkey", package: "VaporValkey"),
        .product(name: "Valkey", package: "valkey-swift"),
    ])
]
```

## Configure

[`ValkeyClient`](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey/valkeyclient) and [`ValkeyClusterClient`](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey/valkeyclusterclient) use a connection pool, and there are several options to configure individual connections as well as the pools themselves.

The bare minimum required for configuring a Valkey client is to provide a URL to connect to:

```swift
import Valkey
import Vapor
import VaporValkey

let app = Application()

app.valkey = ValkeyClient(
    .hostname("localhost"),
    eventLoopGroup: app.eventLoopGroup,
    logger: app.logger
)
```

When assigning the `Application`'s `valkey` property, the `Application` will take ownership of the Valkey client's lifecycle.
Specifically, this assignment operation will automatically run the client and its connection pool, and they will be automatically cancelled when the `Application` is shut down.

The `Application`'s `valkey` property can accept either [`ValkeyClient`](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey/valkeyclient) or [`ValkeyClusterClient`](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey/valkeyclusterclient).
For more information about these clients and their configuration, see the [**valkey-swift** documentation](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey).

## Sending a Command

You can send commands using the `.valkey` property on any [`Application`](https://api.vapor.codes/vapor/application) or [`Request`](https://api.vapor.codes/vapor/request) instance, which will give you access to a [`ValkeyClientProtocol`](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey/valkeyclientprotocol).

Any `ValkeyClientProtocol` has several extensions for all of the various [Valkey commands](https://valkey.io/commands/).

```swift
import Valkey
import Vapor
import VaporValkey

try await app.valkey.set("mykey", value: "myvalue")

let value: RESPBulkString? = try await app.valkey.get("my_key")
if let value {
    print(String(value))
}
```

## Pub/Sub Mode

Valkey and Redis support the ability to enter a ["Pub/Sub" mode](https://valkey.io/topics/pubsub/) where a connection can listen to specific "_channels_" and run specific closures when the subscribed channels publish a "_message_" (some data value).

There is a defined lifecycle to a subscription:

1. **subscribe**: invoked once when the subscription first starts
1. **message**: invoked 0+ times as messages are published to the subscribed channels
1. **unsubscribe**: invoked once when the subscription ends, either by request or the connection being lost

Use `subscribe(to:process:)` to subscribe to one or more channels and receive every message published to those channels as an `AsyncSequence`.
When you exit the closure, the Valkey client sends the relevant UNSUBSCRIBE messages.

```swift
import Valkey
import Vapor
import VaporValkey

try await app.valkey.publish(channel: "channel", message: "Hello, World!")

try await app.valkey.subscribe(to: ["channel"]) { subscription in
    for try await item in subscription {
        print(item.channel)
        print(String(item.message))
    }
}
```

See the documentation of **valkey-swift** on [pub/sub](https://swiftpackageindex.com/valkey-io/valkey-swift/documentation/valkey/pubsub) to learn more about all available subscription features and usage patterns.
