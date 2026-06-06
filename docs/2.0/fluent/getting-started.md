# Getting Started with Fluent

Fluent provides an easy, simple, and safe API for working with your persisted data. Each database table/collection is represented by a `Model` that can be used to interact with the data. Fluent supports common operations like creating, reading, updating, and deleting models. It also supports more advanced operations like joining, relating, and soft deleting. 

!!! note
    Don't forget to add `import FluentProvider` (or your other database provider) to the top of your Swift files.

Fluent ships with SQLite by default. You can use SQLite to quickly scaffold your application with the in-memory database it provides. This is enabled by default in Vapor's default template. To learn more about configuring your database, check out the available [drivers](#drivers).

## Creating a Model

Models are the Swift representations of the data in your database. As such, they are central to most of Fluent's APIs.

Let's take a look at what a simple model looks like.

```swift
final class Pet: Model {
    var name: String
    var age: Int
    let storage = Storage()
    
    init(row: Row) throws {
        name = try row.get("name")
        age = try row.get("age")
    }

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("age", age)
        return row
    }
}
```

Here we are creating a simple class `Pet` with a name and an age. We will add a simple init method for creating new pets.

### Storage

The `storage` property is there to allow Fluent to store extra information on your model--things like the model's database id. 

### Row

The `Row` struct represents a database row. Your models should be able to parse from and serialize to database rows.

#### Parse

Here's the code for parsing the Pet from the database.

```swift
final class Pet: Model {
    ...

    init(row: Row) throws {
        name = try row.get("name")
        age = try row.get("age")
    }
}
```

#### Serialize

Here's the code for serializing the Pet to the database.

```swift
final class Pet: Model {
    ...

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("age", age)
        return row
    }
}
```

## Preparing the Database

In order to use your model, you may need to prepare your database with an appropriate schema.

### Preparation

You can do this by conforming your model to `Preparation`.

```swift
extension Pet: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { pets in
            pets.id()
            pets.string("name")
            pets.int("age")
        }
    } 

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
```

Here we are creating a simple table that will look like this:

| id                       | name   | age |
|--------------------------|--------|-----|
| &lt;database id type&gt; | string | int |

### Add to Droplet

Now you can add your model to the config's preparations so the database is prepared when your application boots.

```swift
import Vapor
import FluentProvider

let config = try Config()
config.preparations.append(Pet.self)
let drop = try Droplet(config)

...
```

## Using Models

Now that we have created our model and prepared the database, we can use it to save and fetch data from the database.

### Save

To save a model, call `.save()`. A new identifier for the model will automatically be created.

```swift
let dog = Pet(name: "Spud", age: 5)
try dog.save()
print(dog.id) // the newly saved pet's id
```

### Find

You can fetch a model from the database using it's ID.

```swift
guard let dog = try Pet.find(42) else {
    throw Abort.notFound
}

print(dog.name) // the name of the dog with id 42
```

### Filter

You can also search for models using filters.

```swift
let dogs = try Pet.makeQuery().filter("age", .greaterThan, 2).all()
print(dogs) // all dogs older than 2

```

## Drivers

Check out the [database](database.md) section for more information about different database drivers you can use with Fluent.

