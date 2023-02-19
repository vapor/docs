# Redis & 会话

Redis 可以作为一个存储提供程序，用于缓存[会话数据](../advanced/sessions.md#session-data)，例如用户凭据。

如果 [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) 未提供自定义委托，则将使用默认值。

## 默认行为

### 创建 SessionID 

除非在你自己的 [`RedisSessionsDelegate`](#redissessionsdelegate) 中实现 [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) 方法，否则所有的 ['SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) 值将通过以下操作创建:

1. 生成32字节的随机字符
1. base64 编码该值

例如：`Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### 存储会话数据

`RedisSessionsDelegate` 的默认实现将使用 `Codable` 将 [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) 存储为一个简单的JSON字符串值。

除非在你自己的 `RedisSessionsDelegate` 中实现了 [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) 方法，`SessionData` 将存储在 Redis 中，其中的键会在 `SessionID` 前加上前缀 `vrs-` (**V**apor **R**edis **S**essions)。

例如：`vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## 注册自定义委托

要自定义数据从 Redis 读取和写入的方式，按如下方式注册 `RedisSessionsDelegate` 对象：

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementation
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> API 文档：[`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

遵循该协议的对象可以用来改变 `SessionData` 在 Redis 中的存储方式。

符合协议的类型只需要实现两个方法：[`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) 和 [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:))

这两者都是必需的，因为你自定义写入会话数据到 Redis 的方式本质上是与如何从 Redis 读取它有内在联系。

### RedisSessionsDelegate 哈希示例

例如，如果你想将会话数据作为 [Hash 存储在 Redis 中](https://redis.io/topics/data-types-intro#redis-hashes)，你将实现如下内容：

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // 将每个数据字段存储为单独的哈希字段
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash 是 [String: RESPValue] 这种类型，因此我们需要尝试解包为字符串
            // 并将每个值存储在数据容器中
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
