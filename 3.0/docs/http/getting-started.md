# Using HTTP

HTTP is a module as part of the `Engine` library containing all HTTP related APIs.

## With Vapor

This package is included with Vapor by default, just add:

```swift
import HTTP
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
        .package(url: "https://github.com/vapor/engine.git", .revision("beta")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["HTTP", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../getting-started/spm.md).

Use `import HTTP` to access HTTP's APIs.
