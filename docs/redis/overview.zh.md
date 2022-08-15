# Redis

[Redis](https://redis.io/) 是一种最流行的内存数据结构存储，通常用作缓存或消息代理。

这个库是 Vapor 和 [**RediStack**](https://gitlab.com/mordil/redistack) 的集成，它是与 Redis 通信的底层驱动程序。

!!! 注意
    Redis 的大部分功能都是由 **RediStack** 提供的。我们强烈建议你熟悉其文档。

    _链接稍后提供。_


## Package

使用 Redis 的第一步是将它作为依赖项添加到你的 Package.swift 文件中。

> 本示例针对已有项目，要了解如何构建新项目，请参阅[入门指南](../getting-started/hello-world.zh.md)。

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/vapor/redis.git", from: "4.0.0")
]
// ...
targets: [
    .target(name: "App", dependencies: [
        // ...
        .product(name: "Redis", package: "redis")
    ])
]
```

## 配置

Vapor 对 [`RedisConnection`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redisconnection) 实例采用池化策略，并且有几个选项可以配置单个连接以及池本身。

配置 Redis 的最低要求是提供一个 URL 来连接：

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redis 配置

> API 文档：[`RedisConfiguration`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/)

#### 服务器地址

如果你有多个 Redis 端点，比如一个 Redis 实例集群，你需要创建一个 [`[SocketAddress]`](https://apple.github.io/swift-nio/docs/current/NIOCore/Enums/SocketAddress.html#/s:3NIO13SocketAddressO04makeC13ResolvingHost_4portACSS_SitKFZ) 集合来传递给初始化器。

创建 `SocketAddress` 最常见的方法是使用  [`makeAddressResolvingHost(_:port:)`](https://apple.github.io/swift-nio/docs/current/NIOCore/Enums/SocketAddress.html#/s:3NIO13SocketAddressO04makeC13ResolvingHost_4portACSS_SitKFZ) 静态方法。

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

对于单个 Redis 端点，使用便利构造器初始化更容易，因为它将为你创建 `SocketAddress`：

- [`.init(url:pool)`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/#redisconfiguration.init(url:pool:)) (带 `String` 或 [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration/#redisconfiguration.init(hostname:port:password:database:pool:))

#### 密码

如果你的 Redis 实例受密码保护，则需要将其作为 `password` 参数传递。

每个连接在创建时都将使用密码进行身份验证。

#### 数据库

这是你希望在创建每个连接时选择的数据库索引。

这使你不必自己将 `SELECT` 命令发送到 Redis。

!!! 警告
    未维护数据库选择。在自己发送 `SELECT` 命令时要小心。

### 连接池选项

> API 文档：[`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/main/Redis/RedisConfiguration_PoolOptions/)

!!! 注意
    这里只突出显示最常更改的选项。对于所有选项，请参考 API 文档。

#### 最小连接数

这是设置你希望每个池始终保持多少连接的值。

值为`0`时，如果连接因任何原因丢失，则池在需要之前不会重新创建它们。

这被称为`冷启动`连接，并且在维持最小连接数方面确实有一些开销。

#### 最大连接数

此选项确定如何维护最大连接数的行为。

!!! 也可以看看
    请参阅 `RedisConnectionPoolSize` API 文档以熟悉更多可用选项。

## 发送命令

你可以使用  [`Application`](https://api.vapor.codes/vapor/main/Vapor/Application/) 或 [`Request`](https://api.vapor.codes/vapor/main/Vapor/Request/) 实例上的 `.redis` 属性发送命令，这使得你可以访问 [`RedisClient`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redisclient)。

对于各别的 [Redis 命令](https://redis.io/commands)，`RedisClient` 都有其对应的扩展。

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### 不支持的命令

如果 **RediStack** 不支持带有扩展方法的命令，你仍然可以手动发送它。

```swift
// command 后的每个值都是 Redis 期望的位置参数
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// or

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## 发布/订阅 模式

Redis 支持进入[发布/订阅模式](https://redis.io/topics/pubsub)，其中连接可以监听特定的`通道`，并在订阅的通道发布`消息`（一些数据值）时运行特定的闭包。

订阅的生命周期定义：

1. **subscribe**：订阅第一次开始时调用一次
1. **message**：在消息发布到订阅频道时调用 0+ 次
1. **unsubscribe**：订阅结束时调用一次，无论是通过请求还是连接丢失

创建订阅时，你必须至少提供一个 [`messageReceiver`](https://swiftpackageindex.com/mordil/redistack/master/documentation/redistack/redissubscriptionmessagereceiver) 来处理订阅频道发布的所有消息。

你可以选择为 `onSubscribe` 和 `onUnsubscribe`  提供一个 `RedisSubscriptionChangeHandler` 来处理它们各自的生命周期事件。

```swift
// 创建2个订阅，每个给定频道一个订阅
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // 处理消息
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
