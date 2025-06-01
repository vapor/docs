# Redis & セッション {#redis-sessions}

Redisは[セッションデータ](../advanced/sessions.md#session-data)（ユーザー認証情報など）をキャッシュするためのストレージプロバイダーとして機能します。

カスタムの[`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)が提供されない場合、デフォルトのものが使用されます。

## デフォルトの動作 {#default-behavior}

### SessionIDの作成 {#sessionid-creation}

[独自の`RedisSessionsDelegate`](#redissessionsdelegate)で[`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne)メソッドを実装しない限り、すべての[`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid)値は以下の手順で作成されます：

1. 32バイトのランダムな文字を生成
1. その値をbase64エンコード

例：`Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### SessionDataの保存 {#sessiondata-storage}

`RedisSessionsDelegate`のデフォルト実装は、[`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata)を`Codable`を使用してシンプルなJSON文字列値として保存します。

独自の`RedisSessionsDelegate`で[`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge)メソッドを実装しない限り、`SessionData`は`SessionID`に`vrs-`（**V**apor **R**edis **S**essions）というプレフィックスを付けたキーでRedisに保存されます。

例：`vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## カスタムデリゲートの登録 {#registering-a-custom-delegate}

Redisへのデータの読み書き方法をカスタマイズするには、独自の`RedisSessionsDelegate`オブジェクトを以下のように登録します：

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // 実装
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate {#redissessionsdelegate}

> APIドキュメント：[`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

このプロトコルに準拠するオブジェクトを使用して、`SessionData`がRedisに保存される方法を変更できます。

プロトコルに準拠する型が実装する必要があるメソッドは2つのみです：[`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:))と[`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:))。

セッションデータをRedisに書き込む方法のカスタマイズは、Redisからデータを読み取る方法と本質的に関連しているため、両方とも必須です。

### RedisSessionsDelegateハッシュの例 {#redissessionsdelegate-hash-example}

例えば、セッションデータを[Redisの**ハッシュ**](https://redis.io/topics/data-types-intro#redis-hashes)として保存したい場合、以下のような実装を行います：

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // 各データフィールドを個別のハッシュフィールドとして保存
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hashは[String: RESPValue]なので、値を文字列として
            // アンラップして各値をデータコンテナに保存する必要があります
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```