# Fluent PostgreSQL

Fluent PostgreSQL ([vapor/fluent-postgresql](https://github.com/vapor/fluent-postgresql)) is a type-safe, fast, and easy-to-use ORM for PostgreSQL built on top of [Fluent](../fluent/getting-started.md).

!!! seealso
    The Fluent PostgreSQL package is built on top of [Fluent](../fluent/getting-started.md) and the pure Swift, NIO-based [PostgreSQL Core](../postgresql/getting-started.md). You should refer to their guides for more information about subjects not covered here.

## Getting Started

This section will show you how to add Fluent PostgreSQL to your project, create your first `PostgreSQLModel`, and make a database query.

### Package

The first step to using Fluent PostgreSQL is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        
        // 🖋🐘 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostgreSQL", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Don't forget to add the module as a dependency in the `targets` array. Once you have added the dependency, regenerate your Xcode project with the following command:

```sh
vapor xcode
```

### Model

Now let's create your first `PostgreSQLModel`. Models represent tables in your PostgreSQL database and they are the primary method of interacting with your data. 

```swift
import FluentPostgreSQL
import Vapor

/// A simple user.
final class User: PostgreSQLModel {
    /// The unique identifier for this user.
    var id: Int?

    /// The user's full name.
    var name: String

    /// The user's current age in years.
    var age: Int

    /// Creates a new user.
    init(id: Int? = nil, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}
```

The example above shows a `PostgreSQLModel` for a simple model representing a user. You can make both `struct`s and `class`es a model. You can even conform types that come from external modules. The only requirement is that these types conform to `Codable`, which must be declared on the base type for synthesized (automatic) conformance.

Standard practice with PostgreSQL databases is using an auto-generated `BIGINT` for creating and storing unique identifiers in the `id` column. It's also possible to use `UUID`s or even `String`s for your identifiers. There are convenience protocol for that. 

|protocol               |type  |key|
|-----------------------|------|---|
|`PostgreSQLModel`      |Int   |id |
|`PostgreSQLUUIDModel`  |UUID  |id |
|`PostgreSQLStringModel`|String|id |

!!! seealso
    Take a look at [Fluent &rarr; Model](../fluent/models.md) for more information on creating models with custom ID types and keys.
    
### Migration

Most of your models will have a corresponding table&mdash;or _schema_&mdash;in your database. You can use [Fluent &rarr; Migration](../fluent/migrations.md) to setup your schemas in a testable, maintainable way. 

If you are creating models to represent an existing table in your database, you don't need a migration. Just set the `defaultDatabase` property on your model so that Fluent knows which database to use if none is specified explicitly.

```swift
User.defaultDatabase = .psql
```

#### Automatic

Fluent makes it easy to automatically generate a migration for your model
    
```swift
/// Allows `User` to be used as a migration.
extension User: PostgreSQLMigration { }
```

That's all it takes. Fluent uses Codable to analyze your model and will attempt to create an appropriate schema for it.

## Configure

The final step is to configure your database. At a minimum, this requires adding two things to your [`configure.swift`](../getting-started/structure.md#configureswift) file.

- `FluentPostgreSQLProvider`
- `MigrationConfig`

Let's take a look.

```swift
import FluentPostgreSQL

/// ...

/// Register providers first
try services.register(FluentPostgreSQLProvider())
    
/// Configure migrations
var migrations = MigrationConfig()
migrations.add(model: User.self, database: .psql)
services.register(migrations)
    
/// Other services....
```

!!! tip
    If this migration you are adding is also a model, you can use the [`add(model:on:)`](#fixme) convenience to automatically set the model's [`defaultDatabase`](#fixme) property. Otherwise, use the [`add(migration:on)`](#fixme) method.

Registering the provider will add all of the services required for Fluent PostgreSQL to work properly. It also includes a default database config struct that uses typical development environment credentials. 

You can of course override this config struct if you have non-standard credentials.

```swift
/// Register custom PostgreSQL Config
let psqlConfig = PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "vapor")
services.register(psqlConfig)
```

Once you have the `MigrationConfig` added, you should be able to run your application and see the following:

```sh
Migrating psql DB
Migrations complete
Server starting on http://localhost:8080
```

## Query

Now that you have created a model and a corresponding schema in your database, let's make your first query.

```swift
router.get("users") { req in
    return User.query(on: req).all()
}
```

If you run your app, and query that route, you should see an empty array returned. Now you just need to add some users! Congratulations on getting your first Fluent PostgreSQL model and migration working.

## Connection

With Fluent, you always have access to the underlying database driver. Using this underlying driver to perform a query is sometimes called a "raw query".

Let's take a look at a raw PostgreSQL query.

```swift
router.get("psql-version") { req -> Future<String> in
    struct Version: Decodable {
        var version: String
    }

    return req.withPooledConnection(to: .psql) { conn in
        return try conn.query("SELECT version() as version;", decoding: Version.self).map { rows in
            return try rows[0].version
        }
    }
}
```

In the above example, `withPooledConnection(to:)` is used to create a connection to the database identified by `.psql`. This is the default database identifier. See [Fluent &rarr; Database](../fluent/database.md#identifier) to learn more.

Once you have the `PostgreSQLConnection`, we can perform a query on it. You can learn more about the methods available in [PostgreSQL &rarr; Core](core.md).
