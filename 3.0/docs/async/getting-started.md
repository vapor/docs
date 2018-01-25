# Using Async

Async is a library revolving around two main concepts:

- [Promises and Futures](futures.md)
- [(Reactive) Streams](streams.md)
- [EventLoops](eventloop.md)

Together they form the foundation of Vapor 3's data flow.

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Async
```

## Without Vapor

Async is a powerful library for any Swift project. To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/async.git", .revision("beta")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Async", ... ])
    ]
)
```

Use `import Async` to access Async's APIs.

To learn the basics, check out [Getting Started &rarr; Async](../deploy/getting-started.md)

<!-- TODO: Update async dependency pointer on release -->
