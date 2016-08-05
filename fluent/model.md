---
currentMenu: fluent-model
---

# Model

`Model` is the base protocol for any of your application's models, especially those you want to persist. 

> `Model` is only available in Vapor, the Fluent equivalent is `Entity`

## Example

Let's create a simple `User` model.

```swift
final class User {
    var name: String

    init(name: String) {
        self.name = name
    }
}
```

The first step to conforming to `Model` is to import Vapor and Fluent.

```swift
import Vapor
import Fluent
```

Then add the conformance to your class.

```swift
final class User: Model { 
    ...
}
```

The compiler will inform you that some methods need to be implemented to conform.

### ID

The first required property is an identifier. This property will contain the identifier when the model is fetched from the database. If it is nil, it will be set when the model is saved.

```swift
final class User: Model {
    var id: Node?
    ...
}
```

### Node Initializable

The next requirement is a way to create the model from the persisted data. Model uses `NodeInitializable` to achieve this.

```swift
final class User: Model {
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
    }
    ...
}
```

The keys `id` and `name` are what we expect the columns or fields in the database to be named. The `extract` call is marked with a `try` because it will throw an error if the value is not present or is the wrong type. 

### Node Representable

Now that we have covered initializing the model, we need to show it how to save back into the database. Model uses `NodeRepresentable` to achieve this.

```swift
final class User: Model {
    func makeNode() throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name
        ])
    }
    ...
}
```

When a `User` is saved, the `makeNode()` method will be called and the resulting `Node` will be saved to the database. The keys `id` and `name` are what we expect the columns or fields in the database to be named.

## Preparations

Some databases, like MySQL, need to be prepared for a new schema. In MySQL, this means creating a new table. 

### Prepare

Let's assume we are using a SQL database. To prepare the database for our `User` class, we need to create a table. If you are using a database like Mongo, you can leave this method unimplemented.

```swift
final class User {
    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("name")
        }
    }
    ...
}
```

Here we create a table named `users` that has an identifier field and a string field with the key `name`. This matches both our `init(node: Node)` and `makeNode() -> Node` methods.

### Revert    

An optional preparation reversion can be created. This will be run if `vapor run prepare --revert` is called. 

```swift
final class User {
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
    ...
}
```

Here we are deleting the table named `users`.

### Droplet

To run these prepations when the applications boots, you must add the Model to the `Droplet`.

```swift
let drop = Droplet(preparations: [User.self])
```

## Full Model

This is what our final `User` model looks like:

```swift
import Vapor
import Fluent

final class User: Model {
    var id: Node?
    var name: String

    init(name: String) {
        self.name = name
    }


    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
    }

    func makeNode() throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name
        ])
    }

    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("name")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}
```

## Interacting

Now that `User` conforms to `Model`, it has a plethora of new methods like `find()`, `query()`, `makeJSON()` and more.

### Fetch

Models can be fetched by their database identifier.

```swift
let user = try User.find(42)
```

### Save

Newly created models can be saved to the database.

```swift
var user = User(name: "Vapor")
try user.save()
print(user.id) // prints the new id
```

### Delete

Persisted models with identifiers can be deleted.

```swift
try user.delete()
```

## Model vs. Entity

Model has a couple of extra conformances that a pure Fluent entity doesn't have.

```swift
public protocol Model: Entity, JSONRepresentable, StringInitializable, ResponseRepresentable {}
```

As can be seen in the protocol, Vapor models can automatically convert to `JSON`, `Response`, and even be used in type-safe routing.




