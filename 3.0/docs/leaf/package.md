# Leaf

Leaf is a templating language that integrates with Futures and Codabel.

### Index

- [Basics](basics.md)
- [Custom commands](custom-commands.md)
- [Pub/Sub](pub-sub.md)
- [Pub/Sub](pipeline.md)

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
