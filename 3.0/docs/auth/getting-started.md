# Getting Started with Auth

Auth ([vapor/auth](https://github.com/vapor/auth)) is a framework for adding authentication to your application. It builds on top of [Fluent](../fluent/getting-started) by using models as the basis of authentication. 

!!! tip
    There is a Vapor API template with Auth pre-configured available.
    See [Getting Started &rarr; Toolbox &rarr; Templates](../getting-started/toolbox.md#templates).

Let's take a look at how you can get started using Auth.

## Package

The first step to using Auth is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...

        // 👤 Authentication and Authorization framework for Fluent.
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Authentication", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Auth currently provides one module `Authentication`. In the future, there will be a separate module named `Authorization` for performing more advanced auth.


## Provider

Once you have succesfully added the Auth package to your project, the next step is to configure it in your application. This is usually done in [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
import Authentication

// register Authentication provider
try services.register(AuthenticationProvider())
```

That's it for basic setup. The next step is to create an authenticatable model. 