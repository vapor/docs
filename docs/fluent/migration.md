# Migrations

Migrations are like a version control system for your database. Each migration defines a change to the database and how to undo it. By modifying your database through migrations, you create a consistent, testable, and shareable way to evolve your databases over time. 

```swift
// An example migration.
struct MyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // Make a change to the database.
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
    	// Undo the change made in `prepare`, if possible.
    }
}
```

If you're using `async`/`await` you should implement the `AsyncMigration` protocol:

```swift
struct MyMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Make a change to the database.
    }

    func revert(on database: Database) async throws {
    	// Undo the change made in `prepare`, if possible.
    }
}
```

The `prepare` method is where you make changes to the supplied `Database`. These could be changes to the database schema like adding or removing a table or collection, field, or constraint. They could also modify the database content, like creating new model instances, updating field values, or doing cleanup.

The `revert` method is where you undo these changes, if possible. Being able to undo migrations can make prototyping and testing easier. They also give you a backup plan if a deploy to production doesn't go as planned. 

## Register

Migrations are registered to your application using `app.migrations`. 

```swift
import Fluent
import Vapor

app.migrations.add(MyMigration())
```

You can add a migration to a specific database using the `to` parameter, otherwise the default database will be used.

```swift
app.migrations.add(MyMigration(), to: .myDatabase)
```

Migrations should be listed in order of dependency. For example, if `MigrationB` depends on `MigrationA`, it should be added to `app.migrations` second.

## Migrate

To migrate your database, run the `migrate` command.

```sh
vapor run migrate
```

You can also run this [command through Xcode](../commands.md#xcode). The migrate command will check the database to see if any new migrations have been registered since it was last run. If there are new migrations, it will ask for a confirmation before running them.

### Revert

To undo a migration on your database, run `migrate` with the `--revert` flag.

```sh
vapor run migrate --revert
```

The command will check the database to see which batch of migrations was last run and ask for a confirmation before reverting them.

### Auto Migrate

If you would like migrations to run automatically before running other commands, you can pass the `--auto-migrate` flag. 

```sh
vapor run serve --auto-migrate
```

You can also do this programatically. 

```swift
try app.autoMigrate().wait()

// or
try await app.autoMigrate()
```

Both of these options exist for reverting as well: `--auto-revert` and `app.autoRevert()`. 

## Next Steps

Take a look at the [schema builder](schema.md) and [query builder](query.md) guides for more information about what to put inside your migrations. 
