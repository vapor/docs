# Database

A Fluent database is responsible for managing connections to your underlying data store and sending queries to the implementation-specific driver you have chosen.

## Drivers

By default, Fluent includes in-memory and SQLite drivers. There are several drivers available to add to your Vapor application.

### Available

| Type       | Key        | Package                                                                      | Class                   | Official |
|------------|------------|------------------------------------------------------------------------------|-------------------------|----------|
| Memory     | memory     | [Fluent Provider](../fluent/package.md)                                      | Fluent.MemoryDriver     | Yes      |
| SQlite     | sqlite     | [Fluent Provider](../fluent/package.md)                                      | Fluent.SQLiteDriver     | Yes      |
| MySQL      | mysql      | [MySQLProvider](../mysql/package.md)                                         | MySQLDriver.Driver      | Yes      |
| PostgreSQL | postgresql | [PostgreSQLProvider](https://github.com/vapor-community/postgresql-provider) | PostgreSQLDriver.Driver | No       |
| MongoDB    | N/A        | [MongoProvider](https://github.com/vapor-community/mongo-provider)           | N/A                     | No       |

Click on the provider package for more information about how to use it.

You can search for a list of available [Vapor database providers](https://github.com/search?utf8=✓&q=topic%3Avapor-provider+topic%3Adatabase&type=Repositories) on GitHub.

## Droplet

You can access the database from the Droplet.

```swift
drop.database // Database?
```

## Preparations

Most databases, like SQL databases, require the schema for a model to be created before it is stored. 
Adding a preparation to your model will allow you to prepare the database while your app boots.

```swift
extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Users
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.int("age")
        }
    }

    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
```

The above prepare statement results in SQL similar to the following:

```sql
CREATE TABLE `users` (`id` INTEGER PRIMARY KEY NOT NULL, `name` TEXT NOT NULL, `age` INTEGER NOT NULL)
```

Once you have created you preparation, add it to the Config's prepratations array.

```swift
config.preparations.append(User.self)
```

### Create

The following methods are available on while creating and modifing the database.

| Method    | Type               |
|-----------|--------------------|
| id        | Primary Identifier |
| foreignId | Foreign Identifier |
| int       | Integer            |
| string    | String             |
| double    | Double             |
| bool      | Boolean            |
| bytes     | Data               |
| date      | Date + Time        |

You can use any of these methods on a builder inside `.create()`.

```swift
try database.create(self) { builder in
    builder.double("latitude")
    builder.double("longitude")
}
```

### Foreign Keys

Foreign keys are automatically added with `.foreignId()`. To add a foreign key manually, use the
`.foreignKey` method.

```swift
try database.create(self) { builder in
    builder.foreignKey("user_id", references: "id", on: User.self)
}
```

To disable automatic foreign keys, set `autoForeignKeys` to false in the `Config/fluent.json` file.

```json
{
    "autoForeignKeys": false
}

```

### Modifier

Existing schema can be modified using the `.modify()` property. All of the methods from `.create()`
are available here as well.

```swift
try database.modify(self) { builder in
    builder.string("name")
    builder.delete("age")
}
```

### Migrations

Other times, you may want to make some modifications to your data set while migrating to a new version or
just performing general cleanup. 

```swift
struct DeleteOldEntries: Preparation {
    static func prepare(_ database: Database) throws {
        try Log.makeQuery().filter(...).delete()
    }

    ...
}
```

### Run

Your preparations will run every time you run your application. You can run your preparations without booting
your server by calling:


```sh
vapor run prepare
```

### Revert

Use the revert method to undo any work you did in the prepare method. 

```swift
extension User: Preparation {
	...


    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
```

You can run the reversions by calling:

```
vapor run prepare --revert
```

This will revert the latest batch of preparations. To revert the entire database, run the following:

```
vapor run prepare --revert --all
```

## Log

Logging queries is a great way to find optimizations for your application and track down bugs.

The easiest way to log queries is to enable logging in your `fluent.json` file.

`Config/fluent.json`
```json
{
    ...,
    "log": true,
    ...
}
```

This will emit info-level logs for all database queries.

### Custom

You can also hook into the database's query logging callback to execute custom logic.

```swift
drop.database?.log = { query in
    print(query)
}
```

You can assign a closure to the `log` property on the database. Any time a query is run, the closure
will be called with a `QueryLog` object containing a string describing the statement and the time it ran.

## Transactions

Transactions allow you to group multiple queries into one single unit of work. If any one of the 
queries experiences a problem, the entire transaction will be rolled back.

```swift
drop.database?.transaction { conn in
    try user.pets.makeQuery(conn).delete()
    try user.makeQuery(conn).delete()
}
```

Drivers that do not support transactions will throw an error if this method is called.

You can use the `.makeQuery(_: Executor)` method to create queries that will run on the 
connection supplied to the closure.

!!! warning
	You must use the connection supplied to the closure for queries you want to include
	in the transaction.


## Indexes

An index is a copy of selected columns of data from a table that can be searched very efficiently.

You can add them to your database by calling `.index()`

```swift
try database.index("name", for: User.self)
```

You can delete them by calling `.deleteIndex()`

```swift
try database.deleteIndex("name", for: User.self)
```
