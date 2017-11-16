# Configuring Fluent

Fluent integrates seamlessly into your Vapor project using [services](../getting-started/application.md#services). 
In this section we will add the Fluent service provider to your application and configure your databases.

!!! warning
    This section assumes you have added both [Fluent](package.md#fluent) and a [Fluent database](package.md#database) to your package.

## Service Provider

The first step to using Fluent, is registering it with your Vapor application.

```swift
import Fluent

...

try services.register(FluentProvider())
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

services.register(databaseConfig)
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

services.register(databaseConfig)
```

### Migrations

If your database uses schemas (most SQL databases do, whereas NoSQL databases don't), you will also want to configure
your migrations using `MigrationConfig`.

```swift
import Fluent

...

var migrationConfig = MigrationConfig()

migrationConfig.add(migration: User.self, database: .foo)

services.register(migrationConfig)
```

You can read more about migrations in [Fluent: Migrations](migrations.md).


## Done

You should now be able to compile and run your application. The next step is to create your
models.
