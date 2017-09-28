# Using Crypto

Crypto is a library containing all common APIs related to cryptography and security.

This project does **not** support TLS. For that, please see [the TLS package](../tls/index.md).

- [Password hashing and verification](passwords.md)
- [Message authentication](random.md)
- [Base64 (also Streaming)](hash.md)
- [Hashes (also Streaming)](hash.md)
- [Random](random.md)

Together they form the foundation of Vapor 3's data flow.

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Crypto
```

## Without Vapor

To include it in your package, add the following to your `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/crypto.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Crypto", ... ])
    ]
)
```

Use `import Async` to access Async's APIs.
