# Using Crypto

Crypto ([vapor/crypto](https://github.com/vapor/crypto)) is a library containing common APIs related to cryptography and data generation. The package contains two modules:

- `Crypto`
- `Random`

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Crypto
import Random
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
      .target(name: "Project", dependencies: ["Crypto", "Random", ... ])
    ]
)
```

Use `import Crypto` to access Crypto's APIs and `import Random` to access Random's APIs.
