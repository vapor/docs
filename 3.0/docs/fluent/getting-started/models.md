# Getting Started with Models

Models are the heart of Fluent. Unlike ORMs in other languages, Fluent doesn't return untyped 
arrays or dictionaries for queries. Instead, you query the database using models. This allows the 
Swift compiler to catch many errors that have burdened ORM users for ages.

In this guide, we will cover the creation of a basic `User` model. See [Fluent &rarr; Model](../model.md) for
more in-depth information about the model protocol.

## Class

Every Fluent model starts with a `Codable` class. You can make any `Codable` class a Fluent model, 
even ones that come from a different module. All you have to do is conform to `Model`. 

```swift
import Foundation

final class User: Codable {
    var id: UUID?
    var name: String
    var age: Int
}
```

Although it's not necessary, adding `final` to your Swift classes can make them more performant
and also make adding `init` methods in extensions easier.

## Conforming to Model

Now that we have our `User` class, let's conform it to `Model`.


```swift
import Fluent

extension User: Model {

}
```

Once you add this conformance requirement, Swift will tell you that it does not yet conform.
Let's add the necessary items to make `User` conform to model.

!!! tip
    We recommend adding `Model` conformance in an extension to help keep your code clean.

### Database

The first step to conforming to `Model` is to let Fluent know which type of database you plan
on using this model with. This allows Fluent to enable database-specific features wherever you
use this model.

```swift
import Fluent
import FluentMySQL

extension User: Model {
    ... 

    /// See Model.Database
    typealias Database = MySQLDatabase
}
```

### ID

Now we can tell Fluent what type of ID this model uses. In this example, our `User` model
has an ID property of type `UUID` named `id`.


```swift
import Fluent
import Foundation

extension User: Model {
    ...

    /// See Model.ID
    typealias ID = UUID

    /// See Model.idKey
    static var idKey: IDKey {
        return \.id
    }
}
```

You can use any type that conforms to `IDType` as a Fluent ID. See [Fluent &rarr; Model &rarr; ID](../model.md#id) for more information.
You can also use any property name you'd like for the id.

!!! warning
    Some databases require certain ID keys. For example, MongoDB requires `_id`.

### Key Field Map

In order to prevent duplicate (and error-prone) strings throughout your code, Fluent models declare
a `KeyFieldMap`. This maps your model's properties to their respective database fields.

```swift
import Fluent

extension User: Model {
    ...

    /// See Model.keyFieldMap
    static var keyFieldMap: KeyFieldMap {
        return [
            key(\.id): field("id"),
            key(\.name): field("name"),
            key(\.age): field("age"),
        ]
    }
}
```

Key paths are a type-safe way to declare references to your model's properties.
You can learn more about key paths in the Swift Evolution proposal, [SE-0161](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md).

!!! note
    Unless you have a special use case, you should always 
    just set the `field(...)` and `key(...)` as the same string.

To see what using these key paths looks like in action, check out [Fluent &rarr; Getting Started &rarr; Query](querying.md).


## Example

We now have a fully-conformed Fluent model!


```swift
import Fluent
import FluentMySQL
import Foundation

final class User: Codable {
    var id: UUID?
    var name: String
    var age: Int
}

extension User: Model {
    /// See Model.Database
    typealias Database = MySQLDatabase

    /// See Model.ID
    typealias ID = UUID

    /// See Model.idKey
    static var idKey: IDKey {
        return \.id
    }

    /// See Model.keyFieldMap
    static var keyFieldMap: KeyFieldMap {
        return [
            key(\.id): field("id"),
            key(\.name): field("name"),
            key(\.age): field("age"),
        ]
    }
}
```

## Done

Now that you have a working Fluent model, you can move onto [querying](querying.md) your model. 
However, if your database uses schemas, you may need to create a [migration](migrations.md) for your model first.

