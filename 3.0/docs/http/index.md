# Using HTTP

HTTP is a module as part of the `Engine` library containing all HTTP related APIs.

### Index

- [Request](request.md)
- [Response](response.md)
- [Method](method.md)
- [Status](status.md)
- [Headers](headers.md)
- [Body](body.md)
- [Middleware](middleware.md)
- [Multipart](multipart.md)
- [Responder](responder.md)
- [URI](uri.md)

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
        .package(url: "https://github.com/vapor/engine.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["HTTP", ... ])
    ]
)
```

Use `import HTTP` to access HTTP's APIs.
