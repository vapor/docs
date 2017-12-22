# Using Auth

This section outlines how to import the Auth package both with or without a Vapor project.

## With Vapor

The easiest way to use Auth with Vapor is to include the Auth provider. 

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.0.0")),
        .Package(url: "https://github.com/vapor/auth-provider.git", .upToNextMajor(from: "1.0.0"))
    ],
    exclude: [ ... ]
)
```

The Auth provider package adds Auth to your project and adds some additional, vapor-specific conveniences like auth middleware. 

Using `import AuthProvider` will import all of the auth middleware and the Authentication and Authorization modules. 

## Just Auth

At the core of the Auth provider is an Authentication and Authorization module based on Fluent.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/auth.git", .upToNextMajor(from: "1.0.0"))
    ],
    exclude: [ ... ]
)
```

Use `import Auth` to access the core auth classes.
