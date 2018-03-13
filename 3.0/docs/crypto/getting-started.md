# Using Crypto

Crypto is a library containing all common APIs related to cryptography and security.

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Crypto
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
        .package(url: "https://github.com/vapor/crypto.git", .upToNextMajor(from: "x.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Crypto", ... ])
    ]
)
```

Use `import Crypto` to access Crypto's APIs.
