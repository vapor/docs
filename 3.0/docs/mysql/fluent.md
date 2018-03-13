# Fluent MySQL

Fluent MySQL ([vapor/fluent-mysql](https://github.com/vapor/fluent-mysql)) is a type-safe, fast, and easy-to-use ORM for MySQL built on top of [Fluent](../fluent/getting-started.md).

!!! seealso
    The Fluent MySQL package is built on top of [Fluent](../fluent/getting-started.md) and the pure Swift, NIO-based [MySQL core](core.md). You should refer to their guides for more information about subjects not covered here.

## Getting Started

This section will show you how to add Fluent MySQL to your project and create your first `MySQLModel`.

### Package

The first step to using Fluent MySQL is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        
        // 🖋🐬 Swift ORM (queries, models, relations, etc) built on MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc"),
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentMySQL", ...]),
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

Now let's create our first `MySQLModel`. Models represent tables in your MySQL database and they are the primary method of interacting with your data. 

```swift
/// A simple user.
final class User: MySQLModel {
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

The example above shows a `MySQLModel` for a simple model representing a user. You can make both `struct`s and `class`es a model. You can even conform types that come from external modules. The only requirement is that these types conform to `Codable`, which must be declared on the base type for synthesized (automatic) conformance.

Standard practice with MySQL databases is using an auto-generated `INTEGER` for creating and storing unique identifiers in the `id` column. It's also possible to use `UUID`s or even `String`s for your identifiers. There are convenience protocol for that. 

|protocol               |type  |key|
|-----------------------|------|---|
|`MySQLModel`      |Int   |id |
|`MySQLUUIDModel`  |UUID  |id |
|`MySQLStringModel`|String|id |

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

- `FluentMySQLProvider`
- `MigrationConfig`

Let's take a look.

```swift
import FluentMySQL

/// ...

/// Register providers first
try services.register(FluentMySQLProvider())
    
/// Configure migrations
var migrations = MigrationConfig()
migrations.add(model: User.self, database: .mysql)
services.register(migrations)
    
/// Other services....
```

Registering the provider will add all of the services required for Fluent MySQL to work properly. It also includes a default database config struct that uses typical development environment credentials. 

You can of course override this config struct if you have non-standard credentials.

```swift
/// Register custom MySQL Config
let mysqlConfig = MySQLDatabaseConfig(hostname: "localhost", port: 3306, username: "vapor")
services.register(mysqlConfig)
```

Once you have the `MigrationConfig` added, you should be able to run your application and see the following:

```sh
Migrating mysql DB
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

If you run your app, and query that route, you should see an empty array returned. Now you just need to add some users! Congratulations on getting your first Fluent MySQL model and migration working.

## Connection

With Fluent, you always have access to the underlying database driver. Using this underlying driver to perform a query is sometimes called a "raw query".

Let's take a look at a raw MySQL query.

```swift
router.get("mysql-version") { req -> Future<String> in
    return req.withPooledConnection(to: .mysql) { conn in
        return try conn.query("select @@version as v;").map(to: String.self) { rows in
            return try rows[0].firstValue(forColumn: "v")?.decode(String.self) ?? "n/a"
        }
    }
}
```

In the above example, `withPooledConnection(to:)` is used to create a connection to the database identified by `.mysql`. This is the default database identifier. See [Fluent &rarr; Database](../fluent/database.md#identifier) to learn more.

Once we have the `MySQLConnection`, we can perform a query on it. You can learn more about the methods available in [MySQL &rarr; Core](core.md).