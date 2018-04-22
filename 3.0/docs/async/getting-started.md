# Getting Started with Async

The Async module is provided as a part of Vapor Core ([vapor/core](https://github.com/vapor/core)). It is a collection of convenience APIs (mostly extensions) built on top of [SwiftNIO](https://github.com/apple/swift-nio).

!!! tip
    You can read more about SwiftNIO's async types (`Future`,  `Promise`, `EventLoop`, and more) in its GitHub [README](https://github.com/apple/swift-nio/blob/master/README.md) or its [API Docs](https://apple.github.io/swift-nio/docs/current/NIO/index.html).

## Usage

This package is included with Vapor and exported by default. You will have access to all `Async` APIs when you import `Vapor`.

```swift
import Vapor // implies `import Async`
```

### Standalone

The Async module, part of the larger Vapor Core package, can also be used on its own with any Swift project.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Async", ... ])
    ]
)
```

Use `import Async` to access the APIs.

## Overview

Continue to [Async &rarr; Overview](overview.md) for an overview of Async's features.

