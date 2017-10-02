# SQLite Overview

Let's dive into the [vapor/sqlite](https://github.com/vapor/sqlite) package and 
see how to connect to and query a database.

!!! warning
	This documentation provides an overview for the SQLite API. 
	If you are using SQLite with Fluent, you will likely never need to use
	this API. Use [Fluent's APIs](../fluent/overview.md) instead.

Follow the instructions in the [package](package.md) section to add the SQLite package to your project. Once its added, you should be able to use `import SQLite.`

## Database

The first step to making a query is to create a `Database`.

### In Memory

In-memory SQLite databases are great for testing as they aren't persisted between application boots.

```swift
import SQLite

let db = Database(storage: .memory)
```

### File path

SQLite requires a single file to persist the database contents.

```swift
import SQLite

let db = Database(storage: .file(path: "/tmp/db.sqlite"))
```

!!! tip
	If the database file does not already exist, it will be created.

## Connection

Once you have initialized your database, you can create a connection.

```swift
let conn = try db.makeConnection(on: .global())
```

!!! note
	Pay special attention to which `DispatchQueue` you pass to `makeConnection(on:)`. 
	This will be the queue SQLite calls you back on.

!!! tip
	If you are using SQLite with Vapor, make sure to pass the [worker](async/worker.md)'s queue here.

## Query

Once you have a `Connection`, you can use it to create a `Query`.

```swift
let query = conn.query("SELECT * FROM users")
```

### Binding Values

If you are executing a query that has input values, you should bind these using parameters. 

```swift
let query = conn.query("INSERT INTO users (name, age) VALUES (?, ?)")
query.bind("Albert")
query.bind(138)
```

You can also bind values using method chaining.

```swift
let query = conn.query("INSERT INTO users (name, age) VALUES (?, ?)")
	.bind("Albert")
	.bind(138)
```

### Output Stream

If you expect output from your query, you must attach a stream. The easiest way
to do this is by using the `drain` convenience.

```swift
query.drain { row in
	print(row)
}
```

You can also use `drain(into:)` and pass in a custom `InputStream` to capture the query's results.

#### Row

The `Query` will output `Row`s. These are simple structs.

```swift
struct Row {
    var fields: [String: Field]
    subscript(field: String) -> Data? { get }
}

```

You can subscript a `Row` object to get the optional `Data`.

```swift
let nameData = row["name"] // Data?
```

`Data` is an enum that contains all possible types of SQLite data.

```swift
public enum Data {
    case integer(Int)
    case float(Double)
    case text(String)
    case blob(Foundation.Data)
    case null
}
```

For each option, there are convenience properties for casting the `Data` enum.

```swift
let name = row["name"]?.text // String
```


### Run

Once your query is ready to execute, you simply call `.execute()`. This returns a `Future<Void>` 
that will be completed when the query is done executing.

```swift
query.execute().then {
	print("done!")
}
```

#### All

If you simply want to fetch all of the results, you can use the `.all()` convenience.
This will automatically create a stream and return a future containing your results.

```swift
query.all().then { rows in
    print(rows)
}
```

#### Sync

For situations where blocking is appropriate (perhaps in tests) you can use `.sync()` to block
until the query's results are ready and return them directly.

```swift
// don't do this unless blocking is OK
let rows = try conn.query("SELECT * FROM users").sync()
```

### Example

Now for the complete example: 

```swift
import SQLite

let db = Database(storage: .memory)
let conn = try db.makeConnection(on: .global()) // take care to use correct queue
conn.query("SELECT * FROM users")
	.all()
    .then { rows in
        print(rows)
    }
    .catch { err in
        print(err)
    }

// wait for results
```

An example with values being bound:

```swift
import SQLite

let db = Database(storage: .memory)
let conn = try db.makeConnection(on: .global()) // take care to use correct queue
conn.query("INSERT INTO users (name, age) VALUES (?, ?)")
    .bind("Albert")
    .bind(138)
    .execute()
    .then {
        print("done")
    }
    .catch { err in
        print(err)
    }

// wait for results
```
