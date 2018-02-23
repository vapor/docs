# Adding Fluent to your Project

Fluent ([vapor/fluent](https://github.com/vapor/fluent)) is a type-safe, fast, and easy-to-use ORM built for Swift.
It takes advantage of Swift's strong type system to provide an elegant API for your database.

## Database

In addition to adding Fluent to your project, you must also add a Fluent compatible database.
Fluent does not include any databases by default. All official databases have a getting started guide similar to this one.

| database   | library                 | driver                   | guide                                                            |
|------------|-------------------------|--------------------------|------------------------------------------------------------------|
| PostgreSQL | vapor/postgres          | vapor/fluent-postgres    | [PostgreSQL &rarr; Package](../../databases/postgres/getting-started.md) |
| MySQL      | vapor/mysql             | vapor/fluent-mysql       | [MySQL &rarr; Package](../../databases/mysql/getting-started.md)         |
| SQLite     | vapor/sqlite            | vapor/fluent-sqlite      | [SQLite &rarr; Package](../../databases/sqlite/getting-started.md)       |
| MongoDB    | mongokitten/mongokitten | vapor/fluent-mongokitten | [README.md](http://github.com/vapor/fluent-mongokitten/readme.md)|

!!! tip
	Any database can be made to work with Fluent by conforming to its [Database](database.md) protocol.
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
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Fluent", ... ])
    ]
)
```

!!! warning
    The `3.0.0` tag is not available during the pre-release phase. [Check the latest tag &rarr;](https://github.com/vapor/async/releases)

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../../getting-started/spm.md).

!!! note
	Use `import Fluent` to access Fluent's APIs.

Once you have Fluent added to your project, you are ready to configure your database(s).

## Configuring Fluent

Fluent integrates seamlessly into your Vapor project using [services](../getting-started/application.md#services).
In this section we will add the Fluent service provider to your application and configure your databases.

!!! warning
    This section assumes you have added both [Fluent](getting-started.md#fluent) and a [Fluent database](getting-started.md#database) to your package.

## Service Provider

The first step to using Fluent, is registering it with your Vapor application.

```swift
import Fluent

...

try services.instance(FluentProvider())
```

Register the `FluentProvider` in the [configure section](../getting-started/structure.md#configure) of your application.

!!! question
    Learn more about how service providers work in [Getting Started: Application](../getting-started/application.md#providers)
    and [Concepts: Services](../concepts/services.md#providers).


## Config

Once the service provider has been added, we can configure one or more databases
to be used with Fluent.

### Identifier

Each database you use with Fluent must have a unique identifier. The easiest way to
keep track of this identifier is to add it as static extension to `DatabaseIdentifier`.

```swift
import Fluent
import FluentMySQL
import FluentSQLite

extension DatabaseIdentifier {
    static var foo: DatabaseIdentifier<SQLiteDatabase> {
        return .init("foo")
    }

    static var bar: DatabaseIdentifier<MySQLDatabase> {
        return .init("bar")
    }
}
```

Now we can use the identifier anywhere in our project:

```swift
req.database(.foo) { ... }
```

The [configure section](../getting-started/structure.md#configure) of your project is a good place to put this extension.

### Databases

Now that we have created a unique identifier for our database, we can register it
to our application using `DatabaseConfig`. A good place to do this is in the
[configure section](../getting-started/structure.md#configure) of your project.

You can add databases to the `DatabaseConfig` using either a type (`.self`) or an instance.

#### Type

If you register a database type (like `SQLiteDatabase.self`), Fluent will ask the application
to create an instance of your database at boot.

```swift
import Fluent
import FluentSQLite

...

var databaseConfig = DatabaseConfig()

databaseConfig.add(database: SQLiteDatabase.self, as: .foo)

services.instance(databaseConfig)
```

#### Instance

You can also register a pre-initialized database. This is especially useful if you'd
like to configure two instances of the same database type.

```swift
import Fluent
import FluentMySQL

...

var databaseConfig = DatabaseConfig()

let mysql = MySQLDatabase(...)
databaseConfig.add(database: mysql, as: .bar)

services.instance(databaseConfig)
```

### Migrations

If your database uses schemas (most SQL databases do, whereas NoSQL databases don't), you will also want to configure
your migrations using `MigrationConfig`.

```swift
import Fluent

...

var migrationConfig = MigrationConfig()

migrationConfig.add(migration: User.self, database: .foo)

services.instance(migrationConfig)
```

You can read more about migrations in [Fluent: Migrations](migrations.md).


## Done

You should now be able to compile and run your application. The next step is to create your models.
