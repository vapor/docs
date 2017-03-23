---
currentMenu: auth-middleware
---

# Middleware

`AuthMiddleware` is at the core of adding authorization to your project. It is responsible for initializing dependencies, checking credentials, and handling sessions.

## Create

Once you have something that conforms to `Auth.User`, you can create an `AuthMiddleware`. Let's assume we have a class `User` that conforms to `Auth.User`.

> Note: You may need to include a module name before `User` to disambiguate. 

```swift
import Auth

let auth = AuthMiddleware(user: User.self)
```

Creating the `AuthMiddleware` can be that simple, or you can customize it with additional initialization arguments.

### Cookie

Customize the type of cookie the `AuthMiddleware` creates by passing a `CookieFactory`.

```swift
let auth = AuthMiddleware(user: User.self) { value in
	return Cookie(
		name: "vapor-auth",
		value: value,
		expires: Date().addingTimeInterval(60 * 60 * 5), // 5 hours
		secure: true,
		httpOnly: true
	)
}
```

### Cache

A custom `CacheProtocol` can be passed as well. The `MemoryCache` used by default is not persisted between server restarts and does not allow for sharing between multiple running instances.

```swift
import VaporRedis

let redis = RedisCache()
let auth = AuthMiddleware(user: User.self, cache: redis)
```

> Note: This example uses the [redis-provider](https://github.com/vapor/redis-provider) package.

### Realm

To customize the `AuthMiddleware` even further, you can use a custom `Realm`. The `Realm` takes the responsibility of registering and authenticating the user away from the `Auth.User` protocol. 

```swift
let facebook = FacebookRealm()
let auth = AuthMiddleware(user: User.self, realm: facebook)
```

> Note: `FacebookRealm` is hypothetical.

## Add

Once you've created the `AuthMiddleware`, you can add it to the `Droplet`.

```swift
let drop = Droplet()
drop.middleware.append(auth)
```

> Note: If you'd like to enable or disable the middleware based on config files, check out [middleware](../guide/middleware.md).

### Sharing Cache

If you'd like the `Droplet` and the `AuthMiddleware` to share the same `CacheProtocol`, pass the same instance to both.

```
import Vapor
import VaporRedis

let redis = RedisCache()
let auth = AuthMiddleware(user: User.self, cache: redis)

let drop = Droplet()

drop.cache = redis
drop.middleware.append(auth)
```
