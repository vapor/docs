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
guard let joannis = users.findOne("username" == "Joannis" && "active" == true) else {
    return
}
```

### Range

A range is any native swift Range. It is used for `skip` and `limit`.

```swift
// Cursor with the first 10 users
let users1 = users.find(in: ..<10)
let users2 = users.find(in: 10..<20)
let users3 = users.find(in: 30...)
```

### Sort

The [`Sort`](sort.md) is used to sort entities in either ascending or descending order based on one or more fields.

```swift
let maleUsers = users.find("gender" == "male", sortedBy: ["age": .ascending])
```

### Projection

The [projection](projection.md) ensures only the specifies subset of fields are returned. Projections can also be computed fields. Remember that the projection must fit within the Collection's Codable type. If this is not a dictionary(-like) type such as `Document` it will be required that the Document fetched matches the Codable type.

```swift
let adults = users.find("age" >= 21, projecting: ["_id": .excluded, "username": .included])
```

# Troubleshooting

### Ambiguous naming

In some situations you may find that MongoKitten's `Database` or `ClientSettings` are ambiguous with another library. The following lines will help get rid of that.

```swift
typealias MongoDB = MongoKitten.Database
typealias MongoDBSettings = MongoKitten.ClientSettings
```

In the above case you'll have to use the aliases instead of the normal references to `Database` and/or `ClientSettings`. Alternatively you can prefix the occurences of those instances with `MongoKitten.`, indicating you want the `Database` object of the MongoKitten module.
