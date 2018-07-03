# Getting Started with Fluent

Fluent ([vapor/fluent](https://github.com/vapor/fluent)) is a type-safe, fast, and easy-to-use ORM framework built for Swift.
It takes advantage of Swift's strong type system to provide an elegant foundation for building database integrations.

## Driver

Fluent is a framework for building ORMs, not an ORM itself. To use Fluent, you will first need to choose a database driver to use. 

!!! tip
    Fluent can support multiple databases and database drivers per application.

Below is a list of officially supported database drivers for Fluent. 

|database|repo|version|dbid|notes|
|-|-|-|-|-|
|PostgreSQL|[fluent-postgresql](https://github.com/vapor/fluent-postgresql.git)|1.0.0|`psql`|**Recommended**. Open source, standards compliant SQL database. Available on most cloud hosting providers.|
|MySQL|[fluent-mysql](https://github.com/vapor/fluent-mysql)|3.0.0|`mysql`|Popular open source SQL database. Available on most cloud hosting providers. This driver also supports MariaDB.|
|SQLite|[fluent-sqlite](https://github.com/vapor/fluent-sqlite)|3.0.0|`sqlite`|Open source, embedded SQL database. Its simplistic nature makes it a great candiate for prototyping and testing.|
|MongoDB|fluent-mongo|n/a|`mongo`|Coming soon. Popular NoSQL database.|

Replace any Xcode placholders (`<#...#>`) in the code snippets below with the information from this table.

!!! seealso
    You can search GitHub for the tag [`fluent-database`](https://github.com/topics/fluent-database) for a full list of official and third-party Fluent database drivers.

### Package

Once you have decided which driver you want, the next step is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/<#repo#>.git", from: "<#version#>"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Fluent<#Database#>", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Don't forget to add the module as a dependency in the `targets` array. Once you have added the dependency, regenerate your Xcode project with the following command:

```sh
vapor xcode
```

## Model

Now let's create your first model. Models represent tables in your database and they are the primary method of interacting with your data. 

Each driver provides convenience model protocols that extend Fluent's base [`Model`](#fixme) protocol. These convenience types make declaring models more concise.

|protocol|note|
|-|-|
|`<#Database#>Model`|Uses standard ID key and type for database engine.|
|`<#Database#>UUIDModel`|Uses `UUID` IDs with standard key for database engine.|
|`<#Database#>StringModel`|Uses `String` IDs with standard key for database engine.|

For this example, we will use the standard convenience model protocol.

```swift
import Fluent<#Database#>
import Vapor

/// A simple user.
final class User: <#Database#>Model {
    /// The unique identifier for this user.
    var id: ID?

    /// The user's full name.
    var name: String

    /// The user's current age in years.
    var age: Int

    /// Creates a new user.
    init(id: ID? = nil, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}
```

The example above shows a simple model representing a user. You can make both structs and classes a model. You can even conform types that come from external modules. The only requirement is that these types conform to `Codable`, which must be declared on the base type for synthesized (automatic) conformance.

Take a look at [Fluent &rarr; Model](models.md) for more information on creating models with custom ID types and keys.

## Configure

Now that you have a model, you can configure your database. This is done in your [`configure.swift`](../getting-started/structure.md#configureswift) file.

### Provider 

The first step is to register your database driver's provider.

```swift
import Fluent<#Database#>
import Vapor

// Register providers first
try services.register(Fluent<#Database#>Provider())

// Other services....
```

Registering the provider will add all of the services required for your Fluent database to work properly. It also includes a default database config struct that uses typical development environment credentials. 

### Custom

If you are using default configuration for your database (such as default credentials or other config) then this may be the only setup you need to perform. 

See the documentation for your specific database type for more information about custom configuration.

## Migration

If your database driver uses schemas (is a SQL database), you will need to create a [`Migration`](#fixme) for your new model. Migrations allow Fluent to create a table for your model in a reliable, testable way. You can later create additional migrations to update or delete the model's table or even manipulate data in the table.

 To create a migration, you will normally first create a new struct or class to hold the migration. However, models can take advantage of a convenient shortcut. When you create a migration from an existing model type, Fluent can infer an appropriate schema from the model's codable properties.

You can add the migration conformance to a model as an extension or on the base type declaration.

```swift
import Fluent<#Database#>
import Vapor

extension User: <#Database#>Migration { }
``` 

Take a look at [Fluent &rarr; Migration](../fluent/migrations.md) if you are interested in learning more about custom migrations.

### MigrationConfig

Once you have created a migration, you must register it to Fluent using [`MigrationConfig`](#fixme). This is done in your [`configure.swift`](../getting-started/structure.md#configureswift) file.

```swift
import Fluent<#Database#>
import Vapor

// Configure migrations
var migrations = MigrationConfig()
migrations.add(model: User.self, database: .<#dbid#>)
services.register(migrations)

// Other services....
```

!!! tip
    If the migration you are adding is also a model, you can use the [`add(model:on:)`](#fixme) convenience to automatically set the model's [`defaultDatabase`](#fixme) property. Otherwise, use the [`add(migration:on)`](#fixme) method.

Once you have the `MigrationConfig` added, you should be able to run your application and see the following:

```sh
Migrating <#dbid#> DB
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

If you run your app, and query that route, you should see an empty array returned. Now you just need to add some users! Congratulations on getting your first Fluent model working.

## Connection

With Fluent, you always have access to the underlying database driver. Using this underlying driver to perform a query is sometimes called a "raw query". 

To perform raw queries, you need access to a database connection. Vapor's [`Request`](#fixme) type has a number of conveniences for creating new database connections. The recommended method is `withPooledConnection(to:)`.  Learn about other methods in [DatabaseKit &rarr; Overview &rarr; Connections](../database-kit/overview/#connections).

```swift
router.get("raw") { req -> Future<String> in
    return req.withPooledConnection(to: .<#dbid#>) { conn in
        // perform raw query using conn
    }
}
```

Once you have the database connection, you can perform a query on it. You can learn more about the methods available in the database's documentation.

