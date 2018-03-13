# Getting Started with Models

Models are the heart of Fluent. Unlike ORMs in other languages, Fluent doesn't return untyped
arrays or dictionaries for queries. Instead, you query the database using models. This allows the
Swift compiler to catch many errors that have burdened ORM users for ages.

In this guide, we will cover the creation of a basic `User` model.

## Class

Every Fluent model starts with a `Codable` class. You can make any `Codable` class a Fluent model,
even ones that come from a different module. All you have to do is conform to `Model`.

```swift
import Foundation
import Vapor

final class User: Content {
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
import FluentMySQL

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
import FluentMySQL
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

You can use any type that conforms to `IDType` as a Fluent ID. You can also use any property name you'd like for the id.

!!! warning
    Some databases require certain ID keys. For example, MongoDB requires `_id`.


## Example

We now have a fully-conformed Fluent model!


```swift
import FluentMySQL
import Foundation
import Vapor

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
}
```

## Done

Now that you have a working Fluent model, you can move onto [querying](querying.md) your model.
However, if your database uses schemas, you may need to create a [migration](migrations.md) for your model first.
