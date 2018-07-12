# Getting Started with SQL

SQL ([vapor/sql](https://github.com/vapor/sql)) is a library for building and serializing SQL queries in Swift. It has an extensible, protocol-based design and supports DQL, DML, and DDL.

!!! tip
    If you use Fluent, you will usually not need to build SQL queries manually.

## Package

The SQL package is lightweight, pure Swift, and has no dependencies. This means it can be used as a SQL serialization framework any Swift project—even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/sql.git", from: "2.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["SQL", ... ])
    ]
)
```

Use `import SQL` to access the APIs.
