# Getting Started with Migrations

Migrations are a way of making organized, testable, and reliable changes to your database's structure--
even while it's in production!

Migrations are often used for preparing a database schema for your models. However, they can also be used to 
make normal queries to your database.

In this guide we will cover creating both types of migrations.

## Model Schema

Let's take a look at how we can prepare a schema supporting database to accept the 
`User` model from the [previous section](models.md).

Just like we did with the `Model` protocol, we will conform our `User` to `Migration`.

```swift
import Fluent

extension User: Migration {

}
```

Swift will inform us that `User` does not yet conform. Let's add the required methods!

### Prepare

The first method to implement is `prepare`. This method is where you make any of your 
desired changes to the database.

For our `User` model, we simply want to create a table that can store one or more users. To do this,
we will use the `.create(...)` function on the supplied database connection.

```swift
extension User: Migration {
    /// See Migration.prepare
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return connection.create(self) { builder in
            try builder.field(for: \.id)
            try builder.field(for: \.name)
            try builder.field(for: \.age)
        }
    }
}
```

We pass `self` (shorthand for `User.self` since this is a static method) as the first argument to the `.create` method. This indicates
to Fluent that we would like to create a schema for the `User` model.

Next, we pass a closure that accepts a `SchemaBuilder` for our `User` model.
We can then call `.field`on this builder to describe what fields we'd like our table to have.

Since we are passing key paths to our `User` model (indicated by `\.`), Fluent can see what type those properties are.
For most common types (`String`, `Int`, `Double`, etc) Fluent will automatically be able to determine the best
database field type to use.

You can also choose to manually select which database field type to use for a given field.

```swift
try builder.field(type: .text, for: \.name)
```

Learn more about creating, updating, and deleting schemas in [Fluent &rarr; Schema Builder](../schema-builder).

### Revert

Revert is the opposite of prepare. Its job is to undo anything that was done in prepare. It is used when you boot your 
app with the `--revert` option. 

To implement `revert` for our model, we simply use `.delete` to indicate that we would like to delete the schema created for `User`.

```swift
extension User: Migration {
    /// See Migration.revert
    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return connection.delete(self)
    }
}
```

## Example

We now have a fully functioning model with migration!

```swift
extension TestUser: Migration {
    /// See Migration.prepare
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return connection.create(self) { builder in
            try builder.field(for: \.id)
            try builder.field(for: \.name)
            try builder.field(for: \.age)
        }
    }

    /// See Migration.revert
    static func revert(on connection: SQLiteConnection) -> Future<Void> {
        return connection.delete(self)
    }
}
```

## Done

Now that you have a working Fluent model and migration, you can move onto [querying](querying.md) your model. 