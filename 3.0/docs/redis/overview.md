# Using Redis

Redis ([vapor/redis](https://github.com/vapor/redis)) is a pure-Swift, event-driven, non-blocking Redis client built on top of SwiftNIO.

You can use this package to interact send Redis commands to your server directly, or as a cache through Vapor's `KeyedCache` interface. 

## Redis Commands

Let's take a look at how to send and recieve data using Redis commands. 

### Connection

The first thing you will need to send a Redis command is a connection. This package is built on top of DatabaseKit, so you can use any of its convenience methods for creating a new connection. 

For this example, we will use the `withNewConnection(to:)` method to create a new connection to Redis.

```swift
router.get("redis") { req -> Future<String> in
    return req.withNewConnection(to: .redis) { redis in
        // use redis connection
    }
}
```

See [DatabaseKit &rarr; Overview](../database-kit/overview.md) for more information.

### Available Commands

See [`RedisClient`](https://api.vapor.codes/redis/latest/Redis/Classes/RedisClient.html) for a list of all available commands. Here we'll take a look at some common commands.

#### Get / Set

Redis's `GET` and `SET` commands allow you to store and later retrieve data from the server. You can pass any `Codable` type as the value to this command.

```swift
router.get("set") { req -> Future<HTTPStatus> in
    // create a new redis connection
    return req.withNewConnection(to: .redis) { redis in
        // save a new key/value pair to the cache
        return redis.set("hello", to: "world")
            // convert void future to HTTPStatus.ok
            .transform(to: .ok)
    }
}

router.get("get") { req -> Future<String> in
    // create a new redis connection
    return req.withNewConnection(to: .redis) { redis in
        // fetch the key/value pair from the cache, decoding a String
        return redis.get("hello", as: String.self)
            // handle nil case
            .map { $0 ?? "" }
    }
}
```

#### Delete

Redis's `DELETE` command allows you to clear a previously stored key/value pair.

```swift
router.get("del") { req -> Future<HTTPStatus> in
    // create a new redis connection
    return req.withNewConnection(to: .redis) { redis in
        // fetch the key/value pair from the cache, decoding a String
        return redis.delete("hello")
            // convert void future to HTTPStatus.ok
            .transform(to: .ok)
    }
}
```

See [`RedisClient`](https://api.vapor.codes/redis/latest/Redis/Classes/RedisClient.html) for a list of all available commands.

## Keyed Cache

You can also use Redis as the backend to Vapor's [`KeyedCache`](https://api.vapor.codes/database-kit/latest/DatabaseKit/Protocols/KeyedCache.html) protocol.

```swift
router.get("set") { req -> Future<HTTPStatus> in
    let string = try req.query.get(String.self, at: "string")
    return try req.keyedCache(for: .redis).set("string", to: string)
        .transform(to: .ok)
}

router.get("get") { req -> Future<String> in
    return try req.keyedCache(for: .redis).get("string", as: String.self)
        .unwrap(or: Abort(.badRequest, reason: "No string set yet."))
}
```

See [DatabaseKit &rarr; Overview](../database-kit/overview/#keyed-cache) for more information.
