# Redis & Sessions

Redis can act as a storage provider for caching [session data](../sessions.md#session-data) such as user credentials.

If a custom [`RedisSessionsDelegate`](https://api.vapor.codes/redis/master/Redis/RedisSessionsDelegate/) isn't provided, a default will be used with the following behavior.

## Default Behavior

### SessionID Creation

Unless you implement the [`makeNewID()`](https://api.vapor.codes/redis/master/Redis/RedisSessionsDelegate/#redissessionsdelegate.makeNewID()) method in [your own `RedisSessionsDelegate`](#RedisSessionsDelegate), all [`SessionID`](https://api.vapor.codes/vapor/master/Vapor/SessionID/) values will be created by doing the following:

1. Generate 32 bytes of random characters
1. base64 encode the value

For example: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### SessionData Storage

The default implementation of `RedisSessionsDelegate` will store [`SessionData`](https://api.vapor.codes/vapor/master/Vapor/SessionData/) as a simple JSON string value using `Codable`.

Unless you implement the [`makeRedisKey(for:)`](https://api.vapor.codes/redis/master/Redis/RedisSessionsDelegate/#redissessionsdelegate.makeRedisKey(for:)) method in your own `RedisSessionsDelegate`, `SessionData` will be stored in Redis with a key that prefixes the `SessionID` with `vrs-` (**V**apor **R**edis **S**essions)

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

> API Documentation: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/master/Redis/RedisSessionsDelegate/)

An object that conforms to this protocol can be used to change how `SessionData` is stored in Redis.

Only two methods are required to be implemented by a type conforming to the protocol: [`redis(_:storeData:forID:)`](https://api.vapor.codes/redis/master/Redis/RedisSessionsDelegate/#redissessionsdelegate.redis(_:storeData:forID:)) and [`redis(_:fetchDataForID:)`](https://api.vapor.codes/redis/master/Redis/RedisSessionsDelegate/#redissessionsdelegate.redis(_:fetchDataForID:)).

Both are required, as the way you customize writing the session data to Redis is intrinsicly linked to how it is to be read from Redis.
