# Cache

Vapor's `CacheProtocol` allows you to store and fetch items from a cache using optional expiration dates.

By default, the Droplet's cache is set to `MemoryCache`. See the various [providers](#providers) below.

## Store

Storing data into the cache is straightforward.

```swift
try drop.cache.set("hello", "world")
```

### Expiration

When storing data, you can also supply an expiration date.

```swift
try drop.cache.set("ephemeral", 42, expiration: Date(timeIntervalSinceNow: 30))
```

In the above example, the supplied key value pair will expire after 30 seconds.

## Fetch

You can retreive data from the cache using the `.get()` method.

```swift
try drop.cache.get("hello") // "world"
```

## Delete

Keys can be deleted from the cache using the `.delete()` method.

```swift
try drop.cache.delete("hello")
```

## Providers

Here is a list of official cache providers. You can [search GitHub](https://github.com/search?utf8=✓&q=topic%3Avapor-provider+topic%3Acache&type=Repositories) for additional packages.

| Type   | Key    | Description                     | Package                                 | Class       |
|--------|--------|---------------------------------|-----------------------------------------|-------------|
| Memory | memory | In-memory cache. Not persisted. | Vapor                                   | MemoryCache |
| Fluent | fluent | Uses Fluent database.           | [Fluent Provider](../fluent/package.md) | FluentCache |
| Redis  | redis  | Uses Redis database.            | [RedisProvider](../redis/package.md)    | RedisCache  |

### How to Use

To use a different cache provider besides the default `MemoryCache`, make sure you have added the provider to your Package.

```swift
import Vapor
import <package>Provider

let config = try Config()
try config.addProvider(<package>Provider.Provider.self)

let drop = try Droplet(config)


...
```


Then change the Droplet's configuration file.

`Config/droplet.json`

```json
{
    "cache": "<key>"
}
```

