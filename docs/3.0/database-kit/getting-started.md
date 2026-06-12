# Getting Started with Database Kit

Database Kit ([vapor/database-kit](https://github.com/vapor/database-kit)) is a framework for configuring and working with database connections. It includes core services like caching, logging, and connection pooling.

!!! tip
    If you use Fluent, you will usually not need to use Database Kit manually. 
    But learning the APIs may come in handy.

## Package

The Database Kit package is lightweight, pure Swift, and has few dependencies. This means it can be used as a core database framework for any Swift project—even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/database-kit.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["DatabaseKit", ... ])
    ]
)
```

Use `import DatabaseKit` to access the APIs.

## API Docs

The rest of this guide will give you an overview of what is available in the DatabaseKit package. As always, feel free to visit the [API docs](http://api.vapor.codes/database-kit/latest/DatabaseKit/index.html) for more in-depth information.
