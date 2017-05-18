---
currentMenu: auth-middleware
---

# Middleware

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`AuthMiddleware` 是为您的项目添加授权的核心。它负责初始化依赖、检查 credentials和处理 session。

## Create

如果你有一些实现了 `Auth.User` 协议的东西，你能够创建一个 `AuthMiddleware`。我们假设我们有一个实现了`Auth.User` 协议的 `User` 类。

> 注释：你可能需要在 `User` 前面包含模块名用于消除歧义。

```swift
import Auth

let auth = AuthMiddleware(user: User.self)
```

创建 `AuthMiddleware` 是可以像上面那样简单，或者你添加额外的参数去自定义它。

### Cookie

通过传递一个 `CookieFactory` 来定制 `AuthMiddleware` 创建的cookie的类型。

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

自定义的实现了 `CacheProtocol` 协议的对象，也可以作为参数被传入。默认使用的 `MemoryCache` 在服务器重启之间是不会持久化数据的，并且不允许在多个运行的实例之间共享。

```swift
import VaporRedis

let redis = RedisCache()
let auth = AuthMiddleware(user: User.self, cache: redis)
```

> 注意：这个例子使用的是 [redis-provider](https://github.com/vapor/redis-provider) package。

### Realm

To customize the `AuthMiddleware` even further, you can use a custom `Realm`. The `Realm` takes the responsibility of registering and authenticating the user away from the `Auth.User` protocol.
要进一步定制 `AuthMiddleware`，你能使用自定义 `Realm`。`Realm` 负责注册和认证 `Auth.User` 协议之外的用户。
```swift
let facebook = FacebookRealm()
let auth = AuthMiddleware(user: User.self, realm: facebook)
```

> 注意： `FacebookRealm` 是假想的。

## Add

一旦你创建了 `AuthMiddleware`，你能够添加它到 `Droplet`。

```swift
let drop = Droplet()
drop.middleware.append(auth)
```

> 注意：如果你喜欢基于配置文件启用或者禁用中间件，请查看 [middleware](../guide/middleware.md)。

### Sharing Cache

如果你希望 `Droplet` 和 `AuthMiddleware` 共享相同的 `CacheProtocol`，给他们传入相同的实例。

```
import Vapor
import VaporRedis

let redis = RedisCache()
let auth = AuthMiddleware(user: User.self, cache: redis)

let drop = Droplet()

drop.cache = redis
drop.middleware.append(auth)
```
