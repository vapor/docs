# Redis & Sessions

Redis can act as a storage provider for caching [session data](../advanced/sessions.md#session-data) such as user credentials.

If a custom [`RedisSessionsDelegate`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/) isn't provided, a default will be used.

## Default Behavior

### SessionID Creation

Unless you implement the [`makeNewID()`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.makeNewID()) method in [your own `RedisSessionsDelegate`](#redissessionsdelegate), all [`SessionID`](https://api.vapor.codes/vapor/main/Vapor/SessionID/) values will be created by doing the following:

1. Generate 32 bytes of random characters
1. base64 encode the value

For example: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### SessionData Storage

The default implementation of `RedisSessionsDelegate` will store [`SessionData`](https://api.vapor.codes/vapor/main/Vapor/SessionData/) as a simple JSON string value using `Codable`.

Unless you implement the [`makeRedisKey(for:)`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.makeRedisKey(for:)) method in your own `RedisSessionsDelegate`, `SessionData` will be stored in Redis with a key that prefixes the `SessionID` with `vrs-` (**V**apor **R**edis **S**essions)

For example: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Registering A Custom Delegate

To customize how the data is read from and written to Redis, register your own `RedisSessionsDelegate` object as follows:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> API Documentation: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/)

An object that conforms to this protocol can be used to change how `SessionData` is stored in Redis.

Only two methods are required to be implemented by a type conforming to the protocol: [`redis(_:store:with:)`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.redis(_:store:with:)) and [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/main/Redis/RedisSessionsDelegate/#redissessionsdelegate.redis(_:fetchDataFor:)).

Both are required, as the way you customize writing the session data to Redis is intrinsically linked to how it is to be read from Redis.

### RedisSessionsDelegate Hash Example

For example, if you wanted to store the session data as a [**Hash** in Redis](https://redis.io/topics/data-types-intro#redis-hashes), you would implement something like the following:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // stores each data field as a separate hash field
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash is [String: RESPValue] so we need to try and unwrap the
            // value as a string and store each value in the data container
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
