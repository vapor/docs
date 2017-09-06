# Using Core

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Async
```

## Without Vapor

Async is a powerful library for any Swift project. To include it in your package, add the following to your `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/async.git", majorVersion: 2),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Async", ... ])
    ]
)
```

Use `import Async` to access Async's APIs.
