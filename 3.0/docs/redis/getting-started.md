# Getting Started with Redis

Redis ([vapor/redis](https://github.com/vapor/redis)) is a pure-Swift, event-driven, non-blocking Redis client built on top of SwiftNIO.

You can use this package to interact send Redis commands to your server directly, or as a cache through Vapor's `KeyedCache` interface. 

Let's take a look at how you can get started using Redis.

## Package

The first step to using Redis is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...

        // ⚡️Non-blocking, event-driven Redis client.
        .package(url: "https://github.com/vapor/redis.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Redis", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

## Provider

Once you have succesfully added the Auth package to your project, the next step is to configure it in your application. This is usually done in [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
import Redis

// register Redis provider
try services.register(RedisProvider())
```

That's it for basic setup. The next step is to create a Redis connection and send a command.

## Command

First, create a new connection to your Redis database. This package is built on top of DatabaseKit, so you can use any of its convenience methods for creating a new connection. See [DatabaseKit &rarr; Overview](../database-kit/overview.md) for more information.

```swift
router.get("redis") { req -> Future<String> in
    return req.withNewConnection(to: .redis) { redis in
        // use redis connection
    }
}
```

Once you have a connection, you can use it to send a command. Let's send the `"INFO"` command which should return information about our Redis server.

```swift
// send INFO command to redis
return redis.command("INFO")
    // map the resulting RedisData to a String
    .map { $0.string ?? "" }
```

Run your app and query `GET /redis`. You should see information about your Redis server printed as output. Congratulations!

