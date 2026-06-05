# Using HTTP

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import HTTP
```

## Without Vapor

HTTP provides everything you need to create an HTTP-based application for any server-side Swift project. To include it in your package, add the following to your `Package.swift` file.

```Swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/engine.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import HTTP` to access HTTP's APIs
