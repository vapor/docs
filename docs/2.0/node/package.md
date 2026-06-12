# Using Node

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import Node
```

## Without Vapor

Node provides a lot of conveniences for any server-side, or client side Swift project. To include it in your package, add the following to your `Package.swift` file.

```Swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/node.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import Node` to access Node's APIs
