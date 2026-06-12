# Routing

Routing ([vapor/routing](https://github.com/vapor/routing)) is a small framework for routing things like HTTP requests. It lets you register and lookup routes in a router using nested, dynamic path components.

For example, the routing package can help you route a request like the following and collect the values of the dynamic components.

```
/users/:user_id/comments/:comment_id
```

## Vapor

This package is included with Vapor and exported by default. You will have access to all `Routing` APIs when you import `Vapor`.

!!! tip
    If you use Vapor, most of Routing's APIs will be wrapped by more convenient methods. See [Getting Started &rarr; Routing](../getting-started/routing.md) for more information.

```swift
import Vapor
```

## Standalone

The Routing package is lightweight, pure-Swift, and has very few dependencies. This means it can be used as a routing framework for any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/routing.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Routing", ... ])
    ]
)
```

Use `import Routing` to access the APIs.

!!! warning
	Some of this guide may contain Vapor-specific APIs, however most of it should be applicable to the Routing package in general.
	Visit the [API Docs](https://api.vapor.codes/routing/latest/Routing/index.html) for Routing-specific API info.

