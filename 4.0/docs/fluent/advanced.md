# Advanced

## MongoDB

Fluent MongoDB is an integration between [Fluent](../fluent/overview.md) and the [MongoKitten](https://github.com/OpenKitten/MongoKitten/) driver. It leverages Swift's strong type system and Fluent's database agnostic interface using MongoDB.

The most common identifier in MongoDB is ObjectId. You can use this for your project using `@ID(custom: .id)`.
If you need to use the same models with SQL, do not use `ObjectId`. Use `UUID` instead.

```swift
final class User: Model {
    // Name of the table or collection.
    static let schema = "users"

    // Unique identifier for this User.
    // In this case, ObjectId is used
    // Fluent recommends using UUID by default, however ObjectId is also supported
    @ID(custom: .id)
    var id: ObjectId?

    // The User's email address
    @Field(key: "email")
    var email: String

    // The User's password stores as a BCrypt hash
    @Field(key: "password")
    var passwordHash: String

    // Creates a new, empty User instance, for use by Fluent
    init() { }

    // Creates a new User with all properties set.
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Data Modelling

In MongoDB, Models are defined in the same as in any other Fluent environment. The main difference between SQL databases and MongoDB lies in relationships and architecture.

In SQL environments, it's very common to create join tables for relationships between two entities. In MongoDB, however, an array can be used to store related identifiers. Due to the design of MongoDB, it's more efficient and practical to design your models with nested data structures.

### Flexible Data

You can add flexible data in MongoDB, but this code will not work in SQL environments.
To create grouped arbitrary data storage you can use `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent cannot support strictly types queries on these values. You can use a dot notated key path in your query for querying.
This is accepted in MongoDB to access nested values.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### Flexible Data

You can add flexible data in MongoDB, but this code will not work in SQL environments.
To create grouped arbitrary data storage you can use `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent cannot support strictly types queries on these values. You can use a dot notated key path in your query for querying.
This is accepted in MongoDB to access nested values.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### Raw Access

To access the raw `MongoDatabase` instance, cast the database instance to `MongoDatabaseRepresentable` as such:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

From here you can use all of the MongoKitten APIs.
