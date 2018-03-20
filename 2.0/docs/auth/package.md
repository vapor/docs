# Using Auth

This section outlines how to import the Auth package both with or without a Vapor project.

## With Vapor

The easiest way to use Auth with Vapor is to include the Auth provider.

You can achieve this by running:

```bash
vapor provider add auth
```

or by manually modifying your `Package.swift` file:

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

After you added the dependency, fetch it using `vapor update`.

Using `import AuthProvider` will import all of the auth middleware and the Authentication and Authorization modules. 

## Without Vapor

At the core of the Vapor Auth provider is an Authentication and Authorization module based on Fluent, which you can use as a stand-alone package by including the Auth in your `Package.swift` files:

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

After you added the dependency, fetch it using `vapor update`.

Use `import Auth` to access the core auth classes.
