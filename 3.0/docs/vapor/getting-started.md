# Getting Started with Vapor

Check out the main [Getting Started](../getting-started/hello-world.md) guide which covers Vapor specifically. This page is here mostly for consistency with the rest of the packages.

More in-depth information on the APIs included in Vapor, see the sub-sections to the left.

## Package

If you don't want to use one of Vapor's templates to get started, you can always include the framework manually.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Vapor", ... ])
    ]
)
```

Use `import Vapor` to access the APIs.

## API Docs

The rest of this guide will give you an overview of what is available in the Vapor package. As always, feel free to visit the [API docs](http://api.vapor.codes/vapor/latest/Vapor/index.html) for more in-depth information.