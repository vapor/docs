# Using Routing

Routing is a library containing all Routing related APIs.

### Index

- [Basics](basics.md)
- [Route Parameters](parameters.md)
- [Route](route.md)
- [TrieRouter](router.md)

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Routing
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
        .package(url: "https://github.com/vapor/routing.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Routing", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../getting-started/spm.md).

Use `import Routing` to access Routing's APIs.
