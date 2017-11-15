# Adding Fluent to your Project

Fluent ([vapor/fluent](https://github.com/vapor/fluent)) is a type-safe, fast, and easy-to-use ORM built for Swift. 
It takes advantage of Swift's strong type system to provide an elegant API for your database.

## Database

In addition to adding Fluent to your project, you must also add a Fluent driver. 
Fluent does not include any database drivers by default. All official drivers have a getting started guide similar to this one. 

| database   | library                 | driver                   | guide                                                            |
|------------|-------------------------|--------------------------|------------------------------------------------------------------|
| PostgreSQL | vapor/postgres          | vapor/fluent-postgres    | [PostgreSQL > Package](../postgres/package.md)                   |
| MySQL      | vapor/mysql             | vapor/fluent-mysql       | [MySQL > Package](../mysql/package.md)                           |
| SQLite     | vapor/sqlite            | vapor/fluent-sqlite      | [SQLite > Package](../sqlite/package.md)                         |
| MongoDB    | mongokitten/mongokitten | vapor/fluent-mongokitten | [README.md](http://github.com/vapor/fluent-mongokitten/readme.md)|

!!! tip
	Any database can be made to work with Fluent by conforming to its [Database](database-protocol.md) protocol. 
	For a list of all compatible database types, search GitHub for the [fluent-driver](https://github.com/topics/fluent-driver) topic.

## Fluent

After you have added your database driver, simply add the Fluent package to your Package manifest.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Fluent", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../spm/manfiest.md).

!!! note 
	Use `import Fluent` to access Fluent's APIs.

Once you have Fluent added to your project, you are ready to [configure your database(s)](provider.md).
