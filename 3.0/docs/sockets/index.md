# Using Sockets

Sockets is a library containing all Socket related APIs.

### Index

- [TCP Socket](tcp-socket.md)
  - [TCP Client](tcp-client.md)
  - [TCP Server](tcp-server.md)

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Sockets
```

## Without Vapor

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/sockets.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Sockets", ... ])
    ]
)
```

Use `import Sockets` to access Sockets's APIs.
