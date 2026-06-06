# Getting Started with Service

Service ([vapor/service](https://github.com/vapor/service)) is a dependency injection (inversion of control) framework. It allows you to register, configure, and create your application's dependencies in a maintainable way.

```swift
/// register a service during boot
services.register(PrintLogger.self, as: Logger.self)

/// you can then create that service later
let logger = try someContainer.make(Logger.self)
print(logger is PrintLogger) // true
```

You can read more about [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) on Wikipedia. Also be sure to check out the [Getting Started &rarr; Services](../getting-started/services.md) guide.

## Vapor

This package is included with Vapor and exported by default. You will have access to all `Service` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The Service package is lightweight, pure-Swift, and has very few dependencies. This means it can be used as a dependency injection framework for any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/service.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Service", ... ])
    ]
)
```

Use `import Service` to access the APIs.

!!! warning
	Some of this guide may contain Vapor-specific APIs, however most of it should be applicable to the Services package in general.
	Visit the [API Docs](https://api.vapor.codes/service/latest/Service/index.html) for Service-specific API info.

