# Getting Started with Fluent

Fluent provides an easy, simple, and safe API for working with your persisted data. Each database table/collection is represented by a `Model` that can be used to interact with the data. Fluent supports common operations like creating, reading, updating, and deleting models. It also supports more advanced operations like joining, relating, and soft deleting. 

!!! note
    Don't forget to add `import VaporFluent` to the top of your Swift files.

Fluent ships with SQLite by default. You can use SQLite to quickly scaffolding your application with the in-memory database it provides. This is enabled by default in Vapor's default template. To learn more about configuring your database, visit the [Database](database.md) section.

## Creating a Model

Models are the Swift representations of the data in your database. As such, they are central to most of Fluent's APIs.

Let's take a look at what a simple model looks like.

```swift
final class Pet: Model {
    var name: String
    var age: Int
    var storage = Storage()

    ...
}
```

Here we are creating a simple class `Pet` with a name and an age. 

### Storage

The `storage` property is there to allow Fluent to store extra information on your model--things like the model's database id. 

### Row

Next we will add code for parsing the Pet from the database.

```swift
final class Pet: Model {
    ...

    init(row: Row) throws {
        name = try row.get("name")
        age = try row.get("age")
    }
}
```



