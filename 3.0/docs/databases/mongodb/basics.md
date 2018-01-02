# MongoDB Basics

`import MongoKitten` in your file(s) using MongoKitten. This will automatically also import the `BSON` APIs.

## Connecting to MongoDB

To connect to MongoDB you need to provide your connection URI and the database you want to access.
The database will also need access to your [worker](../../async/eventloop.md).

```swift
let database = Database.connect(server: "mongodb://localhost:27017", database: "test-db", worker: worker) // Future<Database>
```

You cannot use the connection globally. If you plan to use this connection globally you'll need to use a lock on it for querying since the connection is not thread safe. This will be added in a later stage of MongoKitten 5's beta.

### Connection as a Service

If you want to use the connection within a Vapor 3 route you'll need to register this connection to your [Services](../../concepts/services.md).

```swift
services.register { container -> ClientSettings in
    return "mongodb://localhost:27017" // Your MongoDB URI here
}

services.register { container -> Database in
    let server = try container.make(ClientSettings.self, for: Database.self)

    // Future<Database>
    let db = try Database.connect(sever: server, database: "my-database", worker: container)

    // Await here, it doesn't hurt performant much and it only needs to wait once per worker
    return try db.await(on: container)
}
```

# CRUD

Before applying a CRUD operation you need to select a Collection first. This is the MongoDB equivalent of a table.

You can subscript a database with a string to get a collection with that name. You do not need to set up a schema first.

```swift
router.get("users") { request in
    let database = try request.make(Database.self)
    let users = database["users"] // Collection<Document>

    ...
}
```

Subscripting will give you a `Collection<Document>`. If you want to read the collection as a different (Codable) type you'll need to `map` the collection to a different type.

```swift
struct User: Codable {
    var _id = ObjectId()
    var username: String
    var age: Int

    init(named name: String, age: Int) {
        self.username = named
        self.age = age
    }
}

let users = database["users"].map(to: User.self)
```

CRUD operations

## Insert

Inserting entities is done by using `.insert` with either one or a sequence of the entity.

```swift
users.insert(user)
users.insertAll([user1, user2, user3])
```

Insert returns a `Future<Reply.Insert>` which you can use to determine if one (or more) inserts failed. Is `reply.ok != 1` the future will not be completed but failed with the reply, instead.

```swift
let reply = users.insertAll([user1, user2, user3])

reply.do { success in
    print("\(success.n) users inserted")
}.catch { error in
    // Insert failed!
}
```

## Find

Using `find` on a collection returns a `Cursor<C>` where `C` is the type nested in the collection as demonstrated above.

`find` can take 4 arguments. A filter, range, sort and projection.

There is also `findOne`, which is useful when you want to exactly one object. This does not support a range expression.

### Filter

The filter is a MongoKitten [`Query`](query.md) object.

```swift
// User?
guard let joannis = users.findOne("username" == "Joannis" && "active" == true) else {
    return
}
```

### Range

A range is any native swift Range. It is used for `skip` and `limit`.

```swift
// Cursor with the first 10 users

let users1 = users.find(in: ..<10) // Cursor<User>
let users2 = users.find(in: 10..<20) // Cursor<User>
let users3 = users.find(in: 30...) // Cursor<User>
```

### Sort

The [`Sort`](sort.md) is used to sort entities in either ascending or descending order based on one or more fields.

```swift
let maleUsers = users.find("gender" == "male", sortedBy: ["age": .ascending]) // Cursor<User>
```

### Projection

The [projection](projection.md) ensures only the specifies subset of fields are returned. Projections can also be computed fields. Remember that the projection must fit within the Collection's Codable type. If this is not a dictionary(-like) type such as `Document` it will be required that the Document fetched matches the Codable type.

```swift
let adults = users.find("age" >= 21, projecting: ["_id": .excluded, "username": .included]) // Cursor<User>
```

## Count

Count is similar to a find operation in that it is a read-only operation. Since it does not return the actual data (only an integer of the total entities found) it does not support projections and sorting. It does support a range expression, although it's not often used.

```swift
let totalUsers = users.count() // Future<Int>
let femaleUsers = users.count("gender" == "female") // Future<Int>
```

## Update

Updating can be done on one or all entities. Updates can either update the entire entity or only a subset of fields.

```swift
let user = User(named: "Joannis", age: 111)

users.update("username" == "Joannis", to: user)
```

Update also indicates a success state in the same way `insert` does.

### Updating fields

Updating a subset of fields can be done more efficiently using

```swift
// Rename `Joannis` -> `JoannisO`
users.update("username" == "Joannis", fields: [
    "username": "JoannisO"
])

// Migrate all users to require a password update
users.update(fields: [
    "resetPassword": true
])
```

### Upsert

If you don't know if an entity exists but want it inserted/updated accordingly you should use `upsert`.

```swift
let user = User(named: "Joannis", age: 111)

users.upsert("_id" == user._id, to: user)
```

## Remove

Remove removes the first or all entities matching a query.

```swift
// Remove me!
users.remove("username" == "Joannis")

// Remove all Dutch users
users.removeAll("country" == "NL")
```

# Troubleshooting

### Ambiguous naming

In some situations you may find that MongoKitten's `Database` or `ClientSettings` are ambiguous with another library. The following lines will help get rid of that.

```swift
typealias MongoDB = MongoKitten.Database
typealias MongoDBSettings = MongoKitten.ClientSettings
```

In the above case you'll have to use the aliases instead of the normal references to `Database` and/or `ClientSettings`. Alternatively you can prefix the occurences of those instances with `MongoKitten.`, indicating you want the `Database` object of the MongoKitten module.
