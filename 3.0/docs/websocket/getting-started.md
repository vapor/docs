# Getting Started with WebSocket

WebSocket ([vapor/websocket](https://github.com/vapor/websocket)) is a non-blocking, event-driven WebSocket library built on SwiftNIO. It makes working with SwiftNIO's WebSocket handlers easy and provides integration with [HTTP](../http/getting-started) clients and servers. Creating a WebSocket echo server takes just a few lines of code.

!!! tip
    If you use Vapor, most of WebSocket's APIs will be wrapped by more convenient methods. 

## Vapor

This package is included with Vapor and exported by default. You will have access to all `WebSocket` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The WebSocket package is lightweight, pure Swift, and only depends on SwiftNIO. This means it can be used as a WebSocket framework any Swift project—even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/websocket.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["WebSocket", ... ])
    ]
)
```

Use `import WebSocket` to access the APIs.

The rest of this guide will give you an overview of what is available in the WebSocket package. As always, feel free to visit the [API docs](http://api.vapor.codes/websocket/latest/WebSocket/index.html) for more in-depth information.