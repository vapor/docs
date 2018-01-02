# MySQL Basics

This guide assumes you've set up MySQL and are connected to MySQL using a connection pool as described in [the getting started guide](getting-started.md).

### Type safety

The MySQL driver is written to embrace type-safety and Codable. We currently *only* expose Codable based results.

## Queries

Queries are any type conforming to the protocol `Query`, which requires being convertible to a `String`.
`String` is a Query by default.

You can receive results from Queries in 4 kinds of formats.

- Stream<Result>
- Future<Result>
- forEach<Result>
- Future<Void>

All examples assume the following model:

```swift
struct User: Codable {
  var username: String
  var passwordHash: String
  var age: Int
}
```

### Futures

Futures are often easier to use but significantly heavier on your memory and thus performance. [They are thoroughly described here](../../async/futures.md)

Querying a database for a future is achieved through the `all` function and requires specifying the `Decodable` type that the results need to be deserialized into.

```swift
 // Future<[User]>
let users = connection.all(User.self, in: "SELECT * FROM users")
```

For partial results (`SELECT username, age FROM`) it is recommended to create a second decodable struct specifically for this query to ensure correctness and type-safety.

```swift
struct UserLoginDetails: Codable {
  var username: String
  var age: Int
}
```

### Streams

Streams, [as described on this page](../../async/streams.md), are a source of information that calls a single reader's callback. Streams are best used in larger datasets to prevent the query from consuming a large amount of memory. The downside of a stream is that you cannot return all results in a single future. You'll need to stream the results to the other endpoint, too. For HTTP [this is described here.](../../advanced/streaming-results-http.md)

Querying a database for a stream of results is achieved through the `stream` function and requires specifying the `Decodable` type that the results need to be deserialized into.

```swift
try connection.stream(User.self, in: "SELECT * FROM users", to: inputStream)
```

This will put all Users into the `inputStream`. This requires `inputStream` to be an `InputStream` accepting `User` as Input.

### ForEach

If you don't need to stream complex results to a third party such as using an HTTP Response you can use `forEach`. This is particularly useful for asynchronous actions such as sending a lot of email to the results of a query without depending on the completion/success of one email for the next email.

```swift
connection.forEach(User.self, in: "SELECT * FROM users") { user in
  print(user.username)
}
```

`forEach` returns a future that you can optionally capture. It will be completed when all users have been processed.

```swift
let completed = connection.forEach(User.self, in: "SELECT * FROM users") { user in
  print(user.username)
}

completed.do {
    print("All users printed")
}.catch { error in
    print("An error occurred while printing the users: \(error)")
}
```

### Single column rows

When the query returns only one column, you can decode resulting rows as a single value.

```swift
let usernames = connection.all(String.self, in: "SELECT username FROM users") // Future<[String]>
```

### Resultless queries

Some queries (mostly administrative queries) do not require/return a response. Instead, they only indicate success or error.

You can execute these queries using the `administrativeQuery` command.

```swift
connection.administrativeQuery("DROP TABLE users")
```

You can handle success or response using the returned future.

```swift
connection.administrativeQuery("DROP TABLE users").then {
  print("success")
}.catch {
  print("failure")
}
```
