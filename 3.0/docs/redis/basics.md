# Redis basic usage

To interact with Redis, you first need to construct a Redis client.
The Redis library primarily supports TCP sockets.

This requires a hostname, port and worker. The eventloop will be used for Redis' Socket. The hostname and port have a default. The hostname is defaulted to `localhost`, and the port to Redis' default port `6379`.

```swift
let client = try RedisClient.connect(on: worker) // Future<RedisClient>
```

The `connect` method will return a future containing the TCP based Redis Client.

## Redis Data Types

Redis has 6 data types:

- null
- Int
- Error
- Array
- Basic String (used for command names and basic replies only)
- Bulk String (used for Strings and binary data blobs)

You can instantiate one from the static functions and variables on `RedisData`.

```swift
let null = RedisData.null

let helloWorld = RedisData.bulkString("Hello World")

let three = RedisData.integer(3)

let oneThroughTen = RedisData.array([
  .integer(1),
  .integer(2),
  .integer(3),
  .integer(4),
  .integer(5),
  .integer(6),
  .integer(7),
  .integer(8),
  .integer(9),
  .integer(10)
])
```

The above is the explicit way of defining Redis Types. You can also use literals in most scenarios:

```swift
let array = RedisData.array([
  [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  ],
  "Hello World",
  "One",
  "Two",
  .null,
  .null,
  "test"
])
```

## CRUD using Redis

From here on it is assumed that your client has been successfully created and is available in the variable `client` as a `RedisClient`.

### Creating a record

Creating a record is done using a `RedisData` for a value and a key.

```swift
client.set("world", forKey: "hello")
```

This returns a future that'll indicate successful or unsuccessful insertion.

### Reading a record

Reading a record is similar, only you'll get a warning if you don't use the returned future.

The `Future<RedisData>` for the key "hello" will be "world" if you created the record as shown above.

```swift
let futureRecord = client.getData(forKey: "hello") // Future<RedisData>
```

### Deleting a record

Deleting a record is similar but allows querying the keys, too.

```swift
client.delete(keys: ["hello"])
```

Where the above command will remove the key "hello", the next command will delete **all** keys from the Redis database.

```swift
client.delete(keys: ["*"])
```
