# Fluent Schema Builder

# Schema Builder

#### Custom

You can also implement custom migrations for more fine-grain control over the schemas generated. For example, you may want to store a User's name using a `VARCHAR(64)` instead of `TEXT`. Just like `PostgreSQLModel`, any `struct` or `class` can conform to `PostgreSQLMigration`.

```swift
/// Creates a table for `User`s. 
struct CreateUser: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(User.self, on: conn) { builder in
            builder.field(for: \.id)
            builder.field(for: \.name, type: .varchar(64))
        }
    }

    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.delete(User.self, on: conn)
    }
}
```

Migrations consist of two methods: `prepare(...)` and `revert(...)`. The prepare method runs once and should prepare the database for storing and fetching your model. The revert method runs only if you need to undo changes to your database and should undo anything you do in the prepare method.

Custom migrations are also useful for situations where you may need to _alter_ an existing table, like to add a new column.

```swift
/// Adds a new field to `User`'s table.
struct AddUsernameToUser: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(User.self, on: conn) { builder in
            builder.field(for: \.username)
        }
    }

    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(User.self) { builder in
            builder.deleteField(for: \.username, on: conn)
        }
    }
}
```

#### Constraints

You can also add foreign key and unique constraints to your models during a migration.

```swift
// creates a foreign key constraint ensuring Post.userID is a valid User.id
builder.foreignKey(from: \Post.userID, to: \User.id)
// creates a unique constraint ensuring no other posts have the same slug
builder.unique(on: \Post.slug)
``` 

!!! seealso
    Take a look at [Fluent &rarr; Migration](../fluent/migrations.md) if you are interested in learning more about migrations.


## Create

Coming soon.

## Update

Coming soon.

## Delete

Coming soon.

## References

Coming soon.