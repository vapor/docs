# SQLite

SQLite ([vapor/sqlite](https://github.com/vapor/sqlite)) is a wrapper around the `libsqlite` C-library.

The higher-level, Fluent ORM guide is located at [Fluent &rarr; Getting Started](../fluent/getting-started.md). Using just the SQLite package directly for your project may be a good idea if any of the following are true:

- You have an existing DB with non-standard structure.
- You rely heavily on custom or complex SQL queries.
- You just plain don't like ORMs.

SQLite core is built on top of [DatabaseKit](../database-kit/getting-started.md) which provides some conveniences like connection pooling and integrations with Vapor's [Services](../getting-started/services.md) architecture.

!!! tip
    Even if you do choose to use [Fluent SQLite](../fluent/getting-started.md), all of the features of SQLite core will be available to you.

## Getting Started

Let's take a look at how you can get started using SQLite core.

### Package

The first step to using SQLite core is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...

        // 🔵 SQLite 3 wrapper for Swift.
        .package(url: "https://github.com/vapor/sqlite.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["SQLite", ...]),
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
import SQLite

/// Register providers first
try services.register(SQLiteProvider())
```

Registering the provider will add all of the services required for SQLite to work properly. It also includes a default database config struct that uses an in-memory DB.

#### Customizing Config

You can of course override the default configuration provided by `SQLiteProvider` if you'd like. 

SQLite supports in-memory and file-based persistance. To configure your database manually, register a [`DatabasesConfig`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabasesConfig.html) struct to your services.

```swift
// Configure a SQLite database
let sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))

/// Register the configured SQLite database to the database config.
var databases = DatabasesConfig()
databases.add(database: sqlite, as: .sqlite)
services.register(databases)
```

See [`SQLiteDatabase`](https://api.vapor.codes/sqlite/latest/SQLite/Classes/SQLiteDatabase.html) and [`SQLiteStorage`](https://api.vapor.codes/sqlite/latest/SQLite/Enums/SQLiteStorage.html) for more information.

SQLite's default database identifier is `.sqlite`. You can create a custom identifier if you want by extending [`DatabaseIdentifier`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabaseIdentifier.html). 

### Query

Now that the database is configured, you can make your first query.

```swift
struct SQLiteVersion: Codable {
    let version: String
}

router.get("sql") { req in
    return req.withPooledConnection(to: .sqlite) { conn in
        return conn.select()
            .column(function: "sqlite_version", as: "version")
            .all(decoding: SQLiteVersion.self)
    }.map { rows in
        return rows[0].version
    }
}
```

Visiting this route should display your SQLite version. 

Here we are making use database connection pooling. You can learn more about creating connections in [DatabaseKit &rarr; Getting Started](../database-kit/getting-started.md).

Once we have a connection, we can use [`select()`](https://api.vapor.codes/sql/latest/SQL/Protocols/SQLConnection.html#/s:3SQL13SQLConnectionPAAE6selectAA16SQLSelectBuilderCyxGyF) to create a `SELECT` query builder. Learn more about building queries in [SQL &rarr; Getting Started](../sql/getting-started.md).

Visit SQLite's [API docs](https://api.vapor.codes/sqlite/latest/SQLite/index.html) for detailed information about all available types and methods.
