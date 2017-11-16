# Redis Provider

After you've [added the Redis Provider package](package.md) to your project, setting the provider up in code is easy.

## Add to Droplet

First, register the `RedisProvider.Provider` with your Droplet.

```swift
import Vapor
import RedisProvider

let config = try Config()
try config.addProvider(RedisProvider.Provider.self)

let drop = try Droplet(config)

...
```

## Configure Vapor

Once the provider is added to your Droplet, you can configure Vapor to use Redis for caching.

`Config/droplet.json`

```json
{
    "cache": "redis"
}
```

!!! seealso
	Learn more about configuration files in the [Settings guide](../configs/config.md).

## Configure Redis

If you run your application now, you will likely see an error that the Redis configuration file is missing. Let's add that now.

### Basic

Here is an example of a simple Redis configuration file.

`Config/redis.json`
```json
{
    "hostname": "127.0.0.1",
    "port": 6379,
    "password": "secret",
    "database": 2
}
```

Both password and database are optional.

!!! note
	It's a good idea to store the Redis configuration file in the `Config/secrets` folder since it may contain sensitive information.

### URL

You can also pass the Redis credentials as a URL.

`Config/redis.json`
```json
{
    "url": "redis://:secret@127.0.0.1:6379/2"
}
```

Both password and database are optional.


## Done

You are now ready to [start using Cache](../cache/package.md) with your Redis database.

