# TLS

The TLS packages allow writing TLS/SSL clients and servers.

## Package.swift

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/mysql.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["MySQL", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../getting-started/spm.md).

Use `import MySQL` to access MySQL' APIs.
