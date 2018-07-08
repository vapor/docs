# Fluent Models

Models are the heart of Fluent. Unlike ORMs in other languages, Fluent doesn't return untyped arrays or dictionaries for queries. Instead, you query the database using models. This allows the Swift compiler to catch many errors that have burdened ORM users for ages.

!!! info
    This guide provides an overview of the `Model` protocol and its associated methods and properties. If you are just getting started, check out the guide for your database at [Fluent &rarr; Getting Started](getting-started.md).

`Model` is a protocol in the `Fluent` module. It extends the `AnyModel` protocol which can be used for type-erasure. 

## Conformance 

Both `struct`s and `class`es can conform to `Model`, however you must pay special attention to Fluent's return types if you use a `struct`. Since Fluent works asynchronously, any mutations to a value-type (`struct`) model must return a new copy of the model as a future result.

Normally, you will conform your model to one of the convenience models available in your database-specific package (i.e., `PostgreSQLModel`). However, if you want to customize additional properties, such as the model's `idKey`, you will want to use the `Model` protocol itself.

Let's take a look at what a basic `Model` conformance looks like.

```swift
/// A simple user.
final class User: Model {
    /// See `Model.Database`
    typealias Database = FooDatabase

    /// See `Model.ID`
    typealias ID = Int

    /// See `Model.idKey`
    static let idKey: IDKey = \.id

    /// The unique identifier for this user.
    var id: Int?

    /// The user's full name.
    var name: String

    /// The user's current age in years.
    var age: Int

    /// Creates a new user.
    init(id: Int? = nil, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}
```

!!! tip
    Using `final` prevents your class from being sub-classed. This makes your life easier.

## Associated Types

`Model` defines a few associated types that help Fluent create type-safe APIs for you to use. Take a look at `AnyModel` if you need a type-erased version with no associated types.

### Database

This type indicates to Fluent which database you intend to use with this model. Using this information, Fluent can dynamically add appropriate methods and data types to any `QueryBuilder`s you create with this model.

```swift
final class User: Model {
    /// See `Model.Database`
    typealias Database = FooDatabase
    /// ...
}
```

It is possible to make this associated type generic by adding a generic type to your class or struct (i.e, `User<T>`). This is useful for cases where you are attempting to create generic extensions to Fluent, like perhaps an additive service provider.

```swift
final class User<D>: Model where D: Database {
    /// See `Model.Database`
    typealias Database = D
    /// ...
}
```

You can add further conditions to `D`, such as `QuerySupporting` or `SchemaSupporting`. You can also dynamically extend and conform your generic model using `extension User where D: ... { }`.

That said, for most cases, you should stick to using a concrete type-alias wherever possible. Fluent 3 is designed to allow you to harness the power of your database by creating a strong connection between your models and the underlying driver. 

### ID 

This property defines the type your model will use for its unique identifier.

```swift
final class User: Model {
    /// See `Model.ID`
    typealias ID = UUID
    /// ...
}
```

This will usually be something like `Int`, `UUID`, or `String` although you can theoretically use any type you like.

## Properties

There are several overridable properties on `Model` that you can use to customize how Fluent interacts with your database.

### Name

This `String` will be used as a unique identifier for your model whenever Fluent needs one.

```swift
final class User: Model {
    /// See `Model.name`
    static let name = "user"
    /// ...
}
```

By default, this is the type name of your model.

### Entity

Entity is a generic word used to mean either "table" or "collection", depending on which type of backend you are using for Fluent.

```swift
final class Goose: Model {
    /// See `Model.entity`
    static let entity = "geese"
    /// ...
}
```

By default, this property will be [name](#name).

### ID Key

The ID key is a writeable [key path](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md) that points to your model's unique identifier property.

Usually this will be a property named `id` (for some databases it is `_id`). However you can theoretically use any key you like.

```swift
final class User: Model {
    /// See `Model.ID`
    typealias ID = String
  
    /// See `Model.entity`
    static let idKey = \.username
    
    /// The user's unique username
    var username: String?
    
    /// ...
}
```

The `idKey` property must point to an optional, writeable (`var`) property with type matching [ID](#id).

## Lifecycle

There are several lifecycle methods on `Model` that you can override to hook into Fluent events.

|method      |description                                                |throwing                    |
|------------|-----------------------------------------------------------|----------------------------|
|`willCreate`|Called before Fluent saves your model (for the first time) |Cancels the save.           |
|`didCreate` |Called after Fluent saves your model (for the first time)  |Save completes. Query fails.|
|`willUpdate`|Called before Fluent saves your model (subsequent saves)   |Cancels the save.           |
|`didUpdate` |Called after Fluent saves your model (subsequent saves)    |Save completes. Query fails.|
|`willRead`  |Called before Fluent returns your model from a fetch query.|Cancels the fetch.          |
|`willDelete`|Called before Fluent deletes your model.                   |Cancels the delete.         |

Here's an example of overriding the `willUpdate(on:)` method.

```swift
final class User: Model {
    /// ...
    
    /// See `Model.willUpdate(on:)`
    func willUpdate(on connection: Database.Connection) throws -> Future<Self> {
        /// Throws an error if the username is invalid
        try validateUsername()
       
        /// Return the user. No async work is being done, so we must create a future manually.
        return Future.map(on: connection) { self }
    }
}
```

## CRUD

The model offers basic CRUD method (create, read, update, delete).

### Create

This method creates a new row / item for an instance of your model in the database.

If your model does not have an ID, calls to `.save(on:)` will redirect to this method.

```swift
let didCreate = user.create(on: req)
print(didCreate) /// Future<User>
```
!!! info
    If you are using a value-type (`struct`), the instance of your model returned by `.create(on:)` will contain the model's new ID.

### Read

Two methods are important for reading your model from the database, `find(_:on:)` and `query(on:)`.

```swift
/// Finds a user with ID == 1
let user = User.find(1, on: req)
print(user) /// Future<User?>
```

```swift
/// Finds all users with name == "Vapor"
let users = User.query(on: req).filter(\.name == "Vapor").all()
print(users) /// Future<[User]>
```

### Update

This method updates the existing row / item associated with an instance of your model in the database.

If your model already has an ID, calls to `.save(on:)` will redirect to this method.

```swift
/// Updates the user
let didUpdate = user.update(on: req)
print(didUpdate) /// Future<User>
```

### Delete

This method deletes the existing row / item associated with an instance of your model from the database.

```swift
/// Deletes the user
let didDelete = user.delete(on: req)
print(didDelete) /// Future<Void>
```

## Methods

`Model` offers some convenience methods to make working with it easier.

### Require ID

This method return's the models ID or throws an error.

```swift
let id = try user.requireID()
```

