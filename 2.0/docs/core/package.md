# Using Core

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import Core
```

## Without Vapor

Core provides a lot of conveniences for any server-side Swift project. To include it in your package, add the following to your `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/core.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import Core` to access Core's APIs.