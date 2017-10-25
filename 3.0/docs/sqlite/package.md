# Using SQLite

The [vapor/sqlite](https://github.com/vapor/sqlite) package is a lightweight, nonblocking/async wrapper around SQLite 3's C API. It provides an intuitive Swift interface for working with SQLite that can be used with any Swift project.

On top of `[vapor/sqlite](https://github.com/vapor/sqlite)`, we have built `[vapor/fluent-sqlite](https://github.com/vapor/fluent-sqlite)`. This package conforms our SQLite wrapper to Fluent's [driver](fluent/driver.md) protocol, allowing SQLite databases to be used with Fluent.

## With Fluent

This package is included with Fluent by default, and serves as Fluent's default database type. To use SQLite with Fluent, just [include Fluent])(fluent/package.md) in your project.

Then use the following to import `SQLite`.

```swift
import SQLite
```

If you need access to the Fluent driver specifically, use:

```swift
import FluentSQLite
```

## Without Fluent

This package was built to be a powerful interface for SQLite whether or not you use Fluent. To include this SQLite package in your project, simply add it to your Package manifest.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/sqlite.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Async", ... ])
    ]
)
```

Use `import SQLite` to access the Swift SQLite APIs.
