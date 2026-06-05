# Using JWT

This section outlines how to import the JWT package both with or without a Vapor project.

## With Vapor

The easiest way to use JWT with Vapor is to include the JWT provider. 

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/jwt-provider.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

The JWT provider package adds JWT to your project and adds some additional, Vapor-specific conveniences like `drop.signers`. 

Use `import JWTProvider`.

## Just JWT

At the core of the JWT provider is a fast, pure-Swift JWT implementation for parsing, serializing, and verifying JSON Web Tokens.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/jwt.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import JWT` to access the `JWT` class.
