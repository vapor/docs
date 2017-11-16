# Using SQLite

The [vapor/sqlite](https://github.com/vapor/sqlite) package is a lightweight, nonblocking/async wrapper around SQLite 3's C API. It provides an intuitive Swift interface for working with SQLite that can be used with any Swift project.

On top of [vapor/sqlite](https://github.com/vapor/sqlite), we have built [vapor/fluent-sqlite](https://github.com/vapor/fluent-sqlite) which allows SQLite databases to be used with Fluent.

## With Fluent

SQLite works great with Fluent, you just need to make sure to add the [vapor/fluent-sqlite](https://github.com/vapor/fluent-sqlite) 
package to your project.

To do this, add the Fluent SQLite package to your Package manifest.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/fluent-sqlite.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["FluentSQLite", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../spm/manfiest.md).

Use `import FluentSQLite` to access SQLite's Fluent compatible APIs.

## Just SQLite

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
