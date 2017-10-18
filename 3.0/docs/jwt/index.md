# JSON Web Token

JSON Web Token is a library containing all JSON Web Token related APIs.

### What is JWT?

JWT is a standard for managing client tokens. Tokens are a form of identification and proof to the server. JWT is cryptographically signed, so it is not possible to falsify the validity of a JWT unless any of the following conditions is met:

- A broken algorithm was used (such as MD5)
- A weak signing key was used and brute-forced
- The signing key used was leaked out to a third party

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

Use `import JWT` to access JSON Web Token's APIs.
