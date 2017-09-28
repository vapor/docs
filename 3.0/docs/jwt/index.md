# Using JSON Web Token

JSON Web Token is a library containing all JSON Web Token related APIs.

### Index

- [JSON Web Signature](jws.md)

## With Vapor

This package is included with Vapor by default, just add:

```swift
import JWT
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
        .package(url: "https://github.com/vapor/jwt.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["JWT", ... ])
    ]
)
```

Use `import JSON Web Token` to access JSON Web Token's APIs.
