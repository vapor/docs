# Using Redis

This section outlines how to import the Redis package both with or without a Vapor project.

## With Vapor

The easiest way to use Redis with Vapor is to include the Redis provider. 

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/redis-provider.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

The Redis provider package adds Redis to your project and conforms it to Vapor's `CacheProtocol`. 

Use `import RedisProvider`.

## Just Redis

At the core of the Redis provider is a pure Swift Redis client. This package can be used by itself to send raw cache queries to your Redis database.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/redis.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import Redis`.
