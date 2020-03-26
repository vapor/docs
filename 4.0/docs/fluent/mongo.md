# Fluent MongoDB

Fluent MongoDB is an integration between [Fluent](../fluent/overview.md) and the [MongoKitten](https://github.com/OpenKitten/MongoKitten/) driver. It leverages Swift's strong type system and Fluent's database agnostic interface using MongoDB.

## Models

Models are defined in the same as in any other Fluent environment. The main difference between SQL databases and MongoDB lies in relationships and architecture.

In SQL environments, it's very common to create join tables for relationships between two entities. In MongoDB, however, an array can be used to store related identifiers. Due to the design of MongoDB, it's more efficient and practical to design your models with nested data structures.

### Nested Types

To create a nested type, this type must be a class conforming to Fields. In addition, it must have an empty initialiser for use by Fluent's query system.

```swift
// A type nested in the User model that contains grouped data
// This allows you to easily include/exclude groups of data from your output
final class Profile: Fields {
  // The field key is how it's stored in the database
  @Field(key: "first_name")
  var firstName: String

  @Field(key: "last_name")
  var lastName: String

  init() { }

  // Creates a new profile with all properties set.
  init(firstName: String, lastName: String) {
      self.firstName = firstName
      self.lastName = lastName
  }
}
```

When creating the nested type, it can be used in your Fluent `Model` as a `Field`.

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

    @Field(key: "profile")
    var profile: Profile

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
