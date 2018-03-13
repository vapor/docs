# Fluent SQLite

Fluent SQLite ([vapor/fluent-sqlite](https://github.com/vapor/fluent-sqlite)) is a type-safe, fast, and easy-to-use ORM for SQLite built on top of [Fluent](../fluent/getting-started.md).

!!! seealso
    The Fluent SQLite package is built on top of [Fluent](../fluent/getting-started.md) and the pure Swift, NIO-based [SQLite core](core.md). You should refer to their guides for more information about subjects not covered here.

## Getting Started

This section will show you how to add Fluent SQLite to your project and create your first `SQLiteModel`.

### Package

The first step to using Fluent SQLite is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        
        // 🖋🐬 Swift ORM (queries, models, relations, etc) built on SQLite.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0-rc"),
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", ...]),
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

Now let's create our first `SQLiteModel`. Models represent tables in your SQLite database and they are the primary method of interacting with your data. 

```swift
/// A simple user.
final class User: SQLiteModel {
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

The example above shows a `SQLiteModel` for a simple model representing a user. You can make both `struct`s and `class`es a model. You can even conform types that come from external modules. The only requirement is that these types conform to `Codable`, which must be declared on the base type for synthesized (automatic) conformance.

Standard practice with SQLite databases is using an auto-generated `INTEGER` for creating and storing unique identifiers in the `id` column. It's also possible to use `UUID`s or even `String`s for your identifiers. There are convenience protocol for that. 

|protocol               |type  |key|
|-----------------------|------|---|
|`SQLiteModel`      |Int   |id |
|`SQLiteUUIDModel`  |UUID  |id |
|`SQLiteStringModel`|String|id |

!!! seealso
    Take a look at [Fluent &rarr; Model](../fluent/models.md) for more information on creating models with custom ID types and keys.
    
### Migration

All of your models (with some rare exceptions) should have a corresponding table&mdash;or _schema_&mdash;in your database. You can use a [Fluent &rarr; Migration](../fluent/migrations.md) to automatically generate this schema in a testable, maintainable way. Fluent makes it easy to automatically generate a migration for your model

!!! tip
    If you are creating models to represent an existing table or database, you can skip this step.
    
```swift
/// Allows `User` to be used as a migration.
extension User: Migration { }
```

That's all it takes. Fluent uses Codable to analyze your model and will attempt to create the best possible schema for it.

Take a look at [Fluent &rarr; Migration](../fluent/migrations.md) if you are interested in customizing this migration.

### Configure

The final step is to configure your database. At a minimum, this requires adding two things to your [`configure.swift`](../getting-started/structure.md#configureswift) file.

- `FluentSQLiteProvider`
- `MigrationConfig`

Let's take a look.

```swift
import FluentSQLite

/// ...

/// Register providers first
try services.register(FluentSQLiteProvider())
    
/// Configure migrations
var migrations = MigrationConfig()
migrations.add(model: User.self, database: .sqlite)
services.register(migrations)
    
/// Other services....
```

Registering the provider will add all of the services required for Fluent SQLite to work properly. It also includes a default database config struct that uses typical development environment credentials. 

You can of course override this config struct if you have non-standard credentials.

```swift
/// Register custom SQLite Config
let sqliteConfig = SQLiteDatabaseConfig(hostname: "localhost", port: 5432, username: "vapor")
services.register(sqliteConfig)
```

Once you have the `MigrationConfig` added, you should be able to run your application and see the following:

```sh
Migrating sqlite DB
Migrations complete
Server starting on http://localhost:8080
```

### Query

Now that you have created a model and a corresponding schema in your database, let's make your first query.

```swift
router.get("users") { req in
    return User.query(on: req).all()
}
```

If you run your app, and query that route, you should see an empty array returned. Now you just need to add some users! Congratulations on getting your first Fluent SQLite model and migration working.

## Connection

With Fluent, you always have access to the underlying database driver. Using this underlying driver to perform a query is sometimes called a "raw query".

Let's take a look at a raw SQLite query.

```swift
router.get("sqlite-version") { req -> Future<String> in
    return req.withPooledConnection(to: .sqlite) { conn in
        return try conn.query("select sqlite_version() as v;").map(to: String.self) { rows in
            return try rows[0].firstValue(forColumn: "v")?.decode(String.self) ?? "n/a"
        }
    }
}
```

In the above example, `withPooledConnection(to:)` is used to create a connection to the database identified by `.sqlite`. This is the default database identifier. See [Fluent &rarr; Database](../fluent/database.md#identifier) to learn more.

Once we have the `SQLiteConnection`, we can perform a query on it. You can learn more about the methods available in [SQLite &rarr; Core](core.md).