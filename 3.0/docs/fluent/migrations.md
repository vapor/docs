# Fluent Migrations

Migrations allow you to make organized, testable, and reliable changes to your database's structure--
even while it's in production.

Migrations are often used for preparing a database schema for your models. However, they can also be used to 
make normal queries to your database.

In this guide we will cover creating both types of migrations.

## Creating and Deleting Schemas

Let's take a look at how we can use migrations to prepare a schema supporting database to store a theoretical `Galaxy` model.

Fill in the Xcode placeholders below with your database's name from [Getting Started &rarr; Choosing a Driver](getting-started/#choosing-a-driver).

```swift
import Fluent<#Database#>

struct Galaxy: <#Database#>Model {
    var id: ID?
    var name: String
}
```

### Automatic Model Migrations

Models provide a shortcut for declaring database migrations. If you conform a type that conforms to [`Model`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html) to [`Migration`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Migration.html), Fluent can infer the model's properties and automatically implement the `prepare(...)` and `revert(...)` methods.

```swift
import Fluent<#Database#>

extension Galaxy: <#Database#>Migration { }
```

This method is especially useful for quick prototyping and simple setups. For most other situations you should consider creating a normal, custom migration. 

Add this automatic migration to your [`MigrationConfig`](https://api.vapor.codes/fluent/latest/Fluent/Structs/MigrationConfig.html) using the `add(model:database:)` method. This is done in [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
var migrations = MigrationConfig()
migrations.add(model: Galaxy.self, database: .<#dbid#>)
services.register(migrations)
```

The `add(model:database:)` method will automatically set the model's [`defaultDatabase`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/Model.html#/s:6Fluent5ModelPAAE15defaultDatabase0D3Kit0D10IdentifierVy0D0QzGSgvpZ) property. 

### Custom Migrations

We can customize the table created for our model by creating a migration and using the static `create` and `delete` methods on [`Database`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/Database.html).

```swift
import Fluent<#Database#>

struct CreateGalaxy: <#Database#>Migration {
    // ... 
}
```

#### Creating a Schema

The most important method in a migration is `prepare(...)`. This is responsible for effecting the migration's changes. For our `CreateGalaxy` migration, we will use our database's static `create` method to create a schema.

```swift
import Fluent<#Database#>

struct CreateGalaxy: <#Database#>Migration {
    // ... 

    static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
        return <#Database#>Database.create(Galaxy.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
        }
    }
}
```

To create a schema, you must pass a model type and connection as the first two parameters. The third parameter is a closure that accepts the [`SchemaBuilder`](https://api.vapor.codes/fluent/latest/Fluent/Protocols/SchemaBuilder.html). This builder has convenience methods for declaring fields in the schema.

You can use the `field(for: <#KeyPath#>)` method to quickly create fields for each of your model's properties. Since this method accepts key paths to the model (indicated by `\.`), Fluent can see what type those properties are. For most common types (`String`, `Int`, `Double`, etc) Fluent will automatically be able to determine the best database field type to use.

You can also choose to manually select which database field type to use for a given field.

```swift
try builder.field(for: \.name, type: <#DataType#>)
```

Each database has it's own unique data types, so refer to your database's documentation for more information.

|database|docs|api docs|
|-|-|-|
|PostgreSQL|[PostgreSQL &rarr; Getting Started](../postgresql/getting-started.md)|[`PostgreSQLDataType`](https://api.vapor.codes/postgresql/latest/PostgreSQL/Structs/PostgreSQLDataType.html)|
|MySQL|[MySQL &rarr; Getting Started](../mysql/getting-started.md)|[`MySQLDataType`](https://api.vapor.codes/mysql/latest/MySQL/Structs/MySQLDataType.html)|
|SQLite|[SQLite &rarr; Getting Started](../sqlite/getting-started.md)|[`SQLiteDataType`](https://api.vapor.codes/sqlite/latest/SQLite/Enums/SQLiteDataType.html)|

#### Deleting a Schema

Each migration should also include a method for _reverting_ the changes it makes. It is used when you boot your 
app with the `--revert` option. 

For a migration that creates a table in the database, the reversion is quite simple: delete the table.

To implement `revert` for our model, we can use our database's static `delete(...)` method to indicate that we would like to delete the schema.

```swift
import Fluent<#Database#>

struct CreateGalaxy: <#Database#>Migration {
    // ... 
    static func revert(on connection: <#Database#>Connection) -> Future<Void> {
        return <#Database#>Database.delete(Galaxy.self, on: connection)
    }
}
```

To delete a schema, you pass a model type and connection as the two required parameters. That's it.

You can always choose to skip a reversion by simplying returning `conn.future(())`. But note that they are especially useful when testing and debugging your migrations.

Add this custom migration to your [`MigrationConfig`](https://api.vapor.codes/fluent/latest/Fluent/Structs/MigrationConfig.html) using the `add(migration:database:)` method. This is done in your [`configure.swift`](../getting-started/structure.md#configureswift) file.

```swift
var migrations = MigrationConfig()
migrations.add(migration: CreateGalaxy.self, database: .<#dbid#>)
services.register(migrations)
```
Make sure to also set the `defaultDatabase` property on your model when using a custom migration. 

```swift
Galaxy.defaultDatabase = .<#dbid#>
```

## Updating a Schema

After you deploy your application to production, you may find it necessary to add or remove fields on an existing model. You can achieve this by creating a new migration. 

For this example, let's assume we want to add a new property `mass` to the `Galaxy` model from the previous section.

```swift
import Fluent<#Database#>

struct Galaxy: <#Database#>Model {
    var id: ID?
    var name: String
    var mass: Int
}
```

Since our previous migration created a table with fields for both `id` and `name`, we need to update that table and add a field for `mass`. We can do this by using the static `update` method on [`Database`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/Database.html).

```swift
import Fluent<#Database#>

struct AddGalaxyMass: <#Database#>Migration {
    // ... 
}
```

Our prepare method will look very similar to the prepare method for a new table, except it will only contain our newly added field. 

```swift
struct AddGalaxyMass: <#Database#>Migration {
    // ... 
    
    static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
        return <#Database#>Database.update(Galaxy.self, on: conn) { builder in
            builder.field(for: \.mass)
        }
    }
}
```

*Note:* In SQLite and maybe other databases that have strict NULL / NOT NULL constraint, you may receive the following error:

> Cannot add a NOT NULL column with default value NULL

Since we declared our `mass` property non-optional (`Int`), we will have to add a special configuration that declares its default value as well. In SQL, this is equivalent to the `DEFAULT` keyword. Therefore, to fix the error, the above code would become:

```swift
struct AddGalaxyMass: SQLiteMigration {
    // ...

    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.update(Galaxy.self, on: conn) { builder in
            let defaultValueConstraint = SQLiteColumnConstraint.default(.literal(0))
            builder.field(for: \.mass, type: .integer, defaultValueConstraint)
        }
    }
}
```

All methods available when creating a schema will be available while updating alongside some new methods for deleting fields. See [`SchemaUpdater`](https://api.vapor.codes/fluent/latest/Fluent/Classes/SchemaUpdater.html) for a list of all available methods.

To revert this change, we must delete the `mass` field from the table.

```swift
struct AddGalaxyMass: <#Database#>Migration {
    // ... 

    static func revert(on conn: <#Database#>Connection) -> Future<Void> {
        return <#Database#>Database.update(Galaxy.self, on: conn) { builder in
            builder.deleteField(for: \.mass)
        }
    }
}
```

Add this migration to your [`MigrationConfig`](https://api.vapor.codes/fluent/latest/Fluent/Structs/MigrationConfig.html) using the `add(migration:database:)` method. This is done in your [`configure.swift`](../getting-started/structure.md#configureswift) file.

```swift
var migrations = MigrationConfig()
// ...
migrations.add(migration: AddGalaxyMass.self, database: .<#dbid#>)
services.register(migrations)
```

## Migrating Data

While migrations are useful for creating and updating schemas in SQL databases, they can also be used for more general purposes in any database. Migrations are passed a connection upon running which can be used to perform arbitrary database queries.

For this example, let's assume we want to do a data cleanup migration on our `Galaxy` model and delete any galaxies with a mass of `0`. 

The first step is to create our new migration type.

```swift
struct GalaxyMassCleanup: <#Database#>Migration {
    // ... 
}
```

In the prepare method of this migration, we will perform a query to delete all galaxies which have a mass equal to `0`.

```swift
struct GalaxyMassCleanup: <#Database#>Migration {
    static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
        return Galaxy.query(on: conn).filter(\.mass == 0).delete()
    }

    // ...
}
```

There is no way to undo this migration since it is destructive. You can omit the `revert(...)` method by returning a pre-completed future.

```swift
struct GalaxyMassCleanup: <#Database#>Migration {
    // ...
    
    static func revert(on conn: <#Database#>Connection) -> Future<Void> {
        return conn.future(())
    }
}
```

Add this migration to your [`MigrationConfig`](https://api.vapor.codes/fluent/latest/Fluent/Structs/MigrationConfig.html) using the `add(migration:database:)` method. This is done in [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
var migrations = MigrationConfig()
// ...
migrations.add(migration: GalaxyMassCleanup.self, database: .<#dbid#>)
services.register(migrations)
```
