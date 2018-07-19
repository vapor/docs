# MySQL

MySQL ([vapor/mysql](https://github.com/vapor/mysql)) is a pure Swift MySQL (and MariaDB) client built on top of [SwiftNIO](https://github.com/apple/swift-nio.git).

The higher-level, Fluent ORM guide is located at [Fluent &rarr; Getting Started](../fluent/getting-started.md). Using just the MySQL package directly for your project may be a good idea if any of the following are true:

- You have an existing DB with non-standard structure.
- You rely heavily on custom or complex SQL queries.
- You just plain don't like ORMs.

MySQL core extends [DatabaseKit](../database-kit/getting-started.md) which provides some conveniences like connection pooling and integrations with Vapor's [Services](../getting-started/services.md) architecture.

!!! tip
    Even if you do choose to use [Fluent MySQL](../fluent/getting-started.md), all of the features of MySQL core will be available to you.

## Getting Started

Let's take a look at how you can get started using MySQL core.

### Package

The first step to using MySQL core is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...

        // 🐬 Pure Swift MySQL client built on non-blocking, event-driven sockets.
        .package(url: "https://github.com/vapor/mysql.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["MySQL", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Don't forget to add the module as a dependency in the `targets` array. Once you have added the dependency, regenerate your Xcode project with the following command:

```sh
vapor xcode
```

### Config

The next step is to configure the database in [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
import MySQL

/// Register providers first
try services.register(MySQLProvider())
```

Registering the provider will add all of the services required for MySQL to work properly. It also includes a default database config struct that uses standard credentials.

#### Customizing Config

You can of course override the default configuration provided by `MySQLProvider` if you'd like. 

To configure your database manually, register a [`DatabasesConfig`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabasesConfig.html) struct to your services.

```swift
// Configure a MySQL database
let mysql = try MySQLDatabase(config: MySQLDatabaseConfig(...))

/// Register the configured MySQL database to the database config.
var databases = DatabasesConfig()
databases.add(database: mysql, as: .mysql)
services.register(databases)
```

See [`MySQLDatabase`](https://api.vapor.codes/mysql/latest/MySQL/Classes/MySQLDatabase.html) and [`MySQLDatabaseConfig`](https://api.vapor.codes/mysql/latest/MySQL/Structs/MySQLDatabaseConfig.html) for more information.

MySQL's default database identifier is `.mysql`. You can create a custom identifier if you want by extending [`DatabaseIdentifier`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabaseIdentifier.html). 

### Query

Now that the database is configured, you can make your first query.

```swift
struct MySQLVersion: Codable {
    let version: String
}

router.get("sql") { req in
    return req.withPooledConnection(to: .mysql) { conn in
        return conn.raw("SELECT @@version as version")
            .all(decoding: MySQLVersion.self)
    }.map { rows in
        return rows[0].version
    }
}
```

Visiting this route should display your MySQL version. 

Here we are making use database connection pooling. You can learn more about creating connections in [DatabaseKit &rarr; Getting Started](../database-kit/getting-started.md).

Learn more about building queries in [SQL &rarr; Getting Started](../sql/getting-started.md).

Visit MySQL's [API docs](https://api.vapor.codes/mysql/latest/MySQL/index.html) for detailed information about all available types and methods.
