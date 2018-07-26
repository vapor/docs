# PostgreSQL

PostgreSQL ([vapor/postgresql](https://github.com/vapor/postgresql)) is a pure Swift PostgreSQL client built on top of [SwiftNIO](https://github.com/apple/swift-nio.git).

The higher-level, Fluent ORM guide is located at [Fluent &rarr; Getting Started](../fluent/getting-started.md). Using just the PostgreSQL package directly for your project may be a good idea if any of the following are true:

- You have an existing DB with non-standard structure.
- You rely heavily on custom or complex SQL queries.
- You just plain don't like ORMs.

PostgreSQL core extends [DatabaseKit](../database-kit/getting-started.md) which provides some conveniences like connection pooling and integrations with Vapor's [Services](../getting-started/services.md) architecture.

!!! tip
    Even if you do choose to use [Fluent PostgreSQL](../fluent/getting-started.md), all of the features of PostgreSQL core will be available to you.

## Getting Started

Let's take a look at how you can get started using PostgreSQL core.

### Package

The first step to using PostgreSQL core is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...

        // 🐘 Non-blocking, event-driven Swift client for PostgreSQL.
        .package(url: "https://github.com/vapor/postgresql.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["PostgreSQL", ...]),
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
import PostgreSQL

/// Register providers first
try services.register(PostgreSQLProvider())
```

Registering the provider will add all of the services required for PostgreSQL to work properly. It also includes a default database config struct that uses standard credentials.

#### Customizing Config

You can of course override the default configuration provided by `PostgreSQLProvider` if you'd like. 

To configure your database manually, register a [`DatabasesConfig`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabasesConfig.html) struct to your services.

```swift
// Configure a PostgreSQL database
let postgresql = try PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(...))

/// Register the configured PostgreSQL database to the database config.
var databases = DatabasesConfig()
databases.add(database: postgresql, as: .psql)
services.register(databases)
```

See [`PostgreSQLDatabase`](https://api.vapor.codes/postgresql/latest/PostgreSQL/Classes/PostgreSQLDatabase.html) and [`PostgreSQLDatabaseConfig`](https://api.vapor.codes/postgresql/latest/PostgreSQL/Structs/PostgreSQLDatabaseConfig.html) for more information.

PostgreSQL's default database identifier is `.psql`. You can create a custom identifier if you want by extending [`DatabaseIdentifier`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Structs/DatabaseIdentifier.html). 

### Query

Now that the database is configured, you can make your first query.

```swift
struct PostgreSQLVersion: Codable {
    let version: String
}

router.get("sql") { req in
    return req.withPooledConnection(to: .psql) { conn in
        return conn.raw("SELECT version()")
            .all(decoding: PostgreSQLVersion.self)
    }.map { rows in
        return rows[0].version
    }
}
```

Visiting this route should display your PostgreSQL version. 

Here we are making use database connection pooling. You can learn more about creating connections in [DatabaseKit &rarr; Getting Started](../database-kit/getting-started.md).

Learn more about building queries in [SQL &rarr; Getting Started](../sql/getting-started.md).

Visit PostgreSQL's [API docs](https://api.vapor.codes/postgresql/latest/PostgreSQL/index.html) for detailed information about all available types and methods.
