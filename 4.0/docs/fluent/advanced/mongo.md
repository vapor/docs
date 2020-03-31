# Fluent MongoDB

Fluent MongoDB is an integration between [Fluent](../fluent/overview.md) and the [MongoKitten](https://github.com/OpenKitten/MongoKitten/) driver. It leverages Swift's strong type system and Fluent's database agnostic interface using MongoDB.

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

## Raw Access

To access the raw `MongoDatabase` instance, cast the database instance to `MongoDatabaseRepresentable` as such:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```
