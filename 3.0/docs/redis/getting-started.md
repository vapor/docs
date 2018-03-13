# Redis

Redis is a Redis client library that can communicate with a Redis database.

### What is Redis?

Redis is an in-memory data store used as a database, cache and message broker. It supports most common data structures. Redis is most commonly used for caching data such as sessions and notifications (between multiple servers).

Redis works as a key-value store, but allows querying the keys, unlike most databases.

## With and without Vapor

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/redis.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Redis", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../getting-started/spm.md).

Use `import Redis` to access Redis' APIs.
