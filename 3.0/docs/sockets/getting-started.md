# Using Sockets

Sockets is a library containing all Socket related APIs. It currently only supports TCP.

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
      .target(name: "Project", dependencies: ["TCP", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../getting-started/spm.md).

Use `import TCP` to access Sockets's APIs.

## Sockets

To create a client or server, you must first create a socket.

```swift
let socket = try TCPSocket()
```

### Clients

A `TCPClient` can then wrap the socket and can be connected to a host and port.

```swift
let client = try TCPClient(socket: socket)

try client.connect(hostname: "example.com", port: 1234)
```

If you want to use `TCPClient` with [async streams](../async/streams.md) you can convert the socket you just created to a stream. This requires a [worker or eventloop](../async/eventloop.md) for notifications.

The `source` will output data that is sent by the other end of the socket whilst the `sink` will accept input which will be written to the other end.

```swift
let incomingDataStream = client.socket.source(on: eventloop)
let outgoingDataStream = client.socket.sink(on: eventloop)
```

If you'd connect the source to the sink, for example, you're creating an echo socket.

```swift
incomingDataStream.output(to: outgoingDataStream)
```
