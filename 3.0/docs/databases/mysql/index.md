# MySQL

This package is a driver for the [MySQL Database](https://en.wikipedia.org/wiki/MySQL), an [RDBMS](https://en.wikipedia.org/wiki/Relational_database_management_system) oriented towards stability and robustness.

This driver supports both MySQL and MariaDB. These two databases are almost identical towards the user.

!!! warning
	This documentation provides an overview for the MySQL API.
	If you are using MySQL with Fluent, you will likely never need to use
	this API. Use [Fluent's APIs](../fluent/overview.md) instead.

### Index

- [Setup](setup.md)
- [Basics](basics.md)

## Package.swift

To include it in your package, add the following to your `Package.swift` file.

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

Use `import MySQL` to access MySQL' APIs.
