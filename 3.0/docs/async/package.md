# Using Async

Async is a library revolving around two main concepts:

- [Streams](stream.md)
- [Promises](promise-future-introduction.md)

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
        .package(url: "https://github.com/vapor/async.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Async", ... ])
    ]
)
```

Use `import Async` to access Async's APIs.
