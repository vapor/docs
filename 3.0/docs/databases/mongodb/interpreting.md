# Interpreting official MongoDB tutorials

https://docs.mongodb.com/manual/reference/ has a lot of tutorials on every detail of MongoDB.
Using them in MongoKitten can be a bit tricky. This guide will explain how they are best applied.

## Documents/BSON Data

MongoDB writes Documents in a JSON-like syntax. The following Documents are taken from the documentation on the MongoDB website.

```js
var document0 = {
  "_id" : ObjectId("512bc95fe835e68f199c8686"),
  "author" : "dave",
  "score" : 80,
  "views" : NumberLong(100),
  "awesome": true,
  "users": [
    { _id: 2, user: "ijk123", status: "A" },
    { _id: 3, user: "xyz123", status: "P" },
    { _id: 4, user: "mop123", status: "P" }
  ]
}
```

These Documents read to this equivalent in BSON.

```swift
let document0: Doucment = [
  "_id": try ObjectId("512bc95fe835e68f199c8686")
  "author": "dave",
  "score": Int32(80),
  "views": 100,
  "aweosme": true,
  "users": [
    ["_id": 2, "user": "ijk123", "status": "A"],
    ["_id": 3, "user": "xyz123", "status": "P"],
    ["_id": 4, "user": "mop123", "status": "P"]
  ]
]
```

As you see, ObjectId works similarly but initializing an creating ObjectId from a String can throw an error.
More information about BSON, the MongoDB data type [on this page](bson.md).

Integers in MongoDB are Int32 by default, MongoKitten uses Int64 by default.
MongoDB and MongoKitten can often use the 2 interchangeably with the exception of large numbers that do not fit in an Int32 (and are requested as Int32).

In Swift your dictionary literals don’t start with `{` and don’t end with `}` but instead also use `[` and `]` for dictionaries.

Dictionaries in Swift require a `String` to have quotes (`"`) around them. In JavaScript syntax this is optional.

## Selecting databases/collections

In the shell `use mydatabase` selects the database named "mydatabase". From here you can use `db.mycollection.find()` to fetch all data in the collection.

In MongoKitten, you can subscript the server and database.
Subscripting the server selects a database, and subscripting the database selects a collection.
Usually you'll be working with a single database, so the following code connects to a single database named "example-db".

```swift
// Connect to the localhost database `example-db` without credentials
let database = try Database.connect(server: "mongodb://localhost:27017", database: "mongokitten-example-db", worker: eventLoop).await(on: eventLoop)

// Select a collection
let mycollection = mydatabase["mycollection"]

// Query all entities
try mycollection.find()
```

## Common operations in collections

Most operations are available on a collection object.
By typing `mycollection.` , Swift will autocomplete a list of available methods.

For inserting you can use `insert` which have various parameters which you can use.
Most parameters have a default and can thus be left out of not needed.

```swift
myCollection.insert([
    "_id": ObjectId(),
    "some": "string",
    "date": Date()
])
```

## Aggregates
If you followed this article you should know the basics of MongoKitten aggregates.
If you, at any point, need a specific stage, you can look for the stage by the MongoDB name in the documentation or make use of autocomplete.

All supported aggregates can be quickly accessed using by simply typing a dot (`.`) inside the pipeline array literal like you would for enum cases.
This will autocomplete to all available static functions that can help you create a stage.

If you miss a stage or want to create a stage manually you can do so by providing a BSON `Document` like this:

```swift
let stage = Stage([
  "$match": [
    "username": [
      "$eq": "Joannis"
    ]
  ]
])
```

The stage must be equal to the Document representation of the stage operators described here.
You can then add this stage as one of the values in the array.

## Document Queries

MongoDB queries can work if converted to a Document.
If you do this, you must either use a literal query like below or write it using the query builder described here.

```swift
let query = Query(document)
let literalQuery: Query = [
  "age": [
    "$gte": 15
  ]
]
```
