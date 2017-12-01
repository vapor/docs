# Using MySQL

The [vapor/mysql](https://github.com/vapor/mysql) package is a lightweight, async pure swift MySQL/MariaDB driver. It provides an intuitive Swift interface for working with MySQL that can be used with any Swift project.

On top of [vapor/mysql](https://github.com/vapor/mysql), we have built [vapor/fluent-sqlite](https://github.com/vapor/fluent-sqlite) which allows SQLite databases to be used with Fluent.

## With Fluent

MySQL works well Fluent, you just need to make sure to add the [vapor/fluent-mysql](https://github.com/vapor/fluent-mysql) package to your project.

To do this, add the Fluent MySQL package to your Package manifest.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/fluent-mysql.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["FluentMySQL", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../../getting-started/spm.md).

Use `import FluentMySQL` to access MySQL's Fluent compatible APIs. [Learn more about the Fluent APIs here](../../fluent/getting-started/provider.md)

## Just MySQL

This package was built to be a powerful interface for MySQL. To include this MySQL package in your project, simply add it to your Package manifest.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/mysql.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["MySQL", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../../getting-started/spm.md).

Use `import SQLite` to access the Swift SQLite APIs.
