# Using MySQL

The [vapor/mysql](https://github.com/vapor/mysql) package is a lightweight, reactive, async and pure swift MySQL/MariaDB driver. It provides an intuitive interface for working with MySQL that can be used with any Swift project.

On top of [vapor/mysql](https://github.com/vapor/mysql), we have built [vapor/fluent-sqlite](https://github.com/vapor/fluent-sqlite) which allows SQLite databases to be used with Fluent.

## Just MySQL

This package was built to be a powerful interface for MySQL. To include this MySQL package in your project, simply add it to your Package manifest.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/mysql.git", .revision("beta")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["MySQL", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../../getting-started/spm.md).

Use `import MySQL` to access the Swift MySQL APIs.

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
        .package(url: "https://github.com/vapor/fluent-mysql.git", .revision("beta")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["FluentMySQL", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../../getting-started/spm.md).

Use `import FluentMySQL` to access MySQL's Fluent compatible APIs. [Learn more about the Fluent APIs here](../../fluent/getting-started/provider.md)

### Setting up services

In order to set up MySQL with Fluent you first need to register the Fluent provider:

```swift
try services.provider(FluentProvider())
```

After this, you need to register the MySQL config and database.

```swift
services.instance(FluentMySQLConfig())

var databaseConfig = DatabaseConfig()

let username = "<mysql-user-here>"
let password = "<mysql-pass-here>"
let database = "<mysql-database>"

let db = MySQLDatabase(hostname: "localhost", user: username, password: password, database: database)
databaseConfig.add(database: db, as: .mysql)
services.instance(databaseConfig)
```

Notice the variable `mysqlDB`. This is an identifier for the MySQL database.
You need to create an identifier for each database you attach to Fluent.

The following identifer can be global, or as a static variable in an extension on `DatabaseIdentifier`.

```swift
extension DatabaseIdentifier {
    static var mysql: DatabaseIdentifier<MySQLDatabase> {
        return .init("foo")
    }
}
```

Last, you can specify migrations for Fluent to execute. This can be used for creating and altering schemas and migrating data within the table.

Fluent `Model`s that conform to the protocol `Migration` automatically inherit a migration for schema creation. Nothing needs to be programmed for this.

```swift
var migrationConfig = MigrationConfig()
migrationConfig.add(model: MyModel.self, database: .mysql)
services.instance(migrationConfig)
```

More info on working with Fluent can be found [here](../../fluent/getting-started/getting-started.md).
