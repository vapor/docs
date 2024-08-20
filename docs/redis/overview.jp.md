# Redis

[Redis](https://redis.io/)は、キャッシュやメッセージブローカーとして一般的に使用される最も人気のあるインメモリデータ構造ストアの1つです。

このライブラリは、Vaporと[**RediStack**](https://github.com/swift-server/RediStack)の間の統合です。RediStackはRedisと通信する基本ドライバです。

!!! 注意
    Redisのほとんどの機能は**RediStack**によって提供されます。
    そのドキュメントに精通していることを強くお勧めします。

## パッケージ

Redisを使用する最初のステップは、Swiftパッケージマニフェスト内のプロジェクトの依存関係としてそれを追加することです。

> この例は既存のパッケージのためのものです。新しいプロジェクトを開始する場合のヘルプについては、メインの[はじめに](../getting-started/hello-world.md)ガイドを参照してください。

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

## 設定

Vaporは、[`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection) インスタンスに対してプーリング戦略を採用しており、個々の接続だけでなくプール自体を構成するためのいくつかのオプションがあります。

Redisを設定するために必要な最低限は、接続するためのURLを提供することです。

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redisの設定

> API ドキュメント: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

複数のRedisエンドポイント（Redisインスタンスのクラスタなど）がある場合は、イニシャライザに渡すために[`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress)コレクションを作成する必要があります。

`SocketAddress`を作成する最も一般的な方法は、[`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:))静的メソッドを使用することです。

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

単一のRedisエンドポイントの場合、SocketAddressを作成するのに便利なイニシャライザを使用するとより簡単になります。

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (with `String` or [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Redisインスタンスがパスワードでセキュリティ保護されている場合、**password**引数としてそれを渡す必要があります。

各接続は作成時にパスワードを使用して認証されます。

#### database

これは、接続が作成されるたびに選択するデータベースインデックスです。

これにより、Redisに**SELECT**コマンドを送信する必要がなくなります。

!!! 警告
データベースの選択は維持されません。**SELECT**コマンドを自分で送信する際は注意してください。

### 接続プールオプション

> API ドキュメント: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! 注意
ここでは、最も一般的に変更されるオプションのみを強調しています。すべてのオプションについては、APIドキュメントを参照してください。

#### minimumConnectionCount

これは、各プールが常に維持する接続の数を設定する値です。

値が **0** の場合、接続が何らかの理由で失われても、プールは必要に応じてそれらを再作成しません。

これは "cold start" 接続として知られ、最小接続数を維持するよりもいくらかのオーバーヘッドがあります。

#### maximumConnectionCount

Tこのオプションは、最大接続数がどのように維持されるかを決定します。

!!! 参照
利用可能なオプションに精通するために **RedisConnectionPoolSize** API を参照してください。

## コマンドの送信

任意の`.redis` または[`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) or [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request)インスタンスの .redis プロパティを使用すると[`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient)にアクセスできます。

任意の`RedisClient`には、さまざまな[Redis commands](https://redis.io/commands)に対するいくつかの拡張機能があります。

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// or

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### サポートされていないコマンド

**RediStack** が拡張メソッドでコマンドをサポートしていない場合、手動で送信することができます。

```swift
// each value after the command is the positional argument that Redis expects
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

## Pub/Sub モード

Redisは、接続が特定の「チャンネル」をリスニングし、購読されたチャンネルが「メッセージ」（データ値）を発行すると、特定のクロージャを実行できる["Pub/Sub" mode](https://redis.io/topics/pubsub)をサポートしています。

購読には定義されたライフサイクルがあります。

1. subscribe: 購読が最初に開始されたときに一度だけ呼び出されます
2. message: 購読されたチャンネルにメッセージが発行されると、0回以上呼び出されます
3. unsubscribe: リクエストまたは接続の喪失によって購読が終了したときに一度だけ呼び出されます

購読を作成するときには、少なくとも[`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver)を提供して、購読されたチャンネルによって発行されたすべてのメッセージを処理する必要があります。

`onSubscribe` と `onUnsubscribe` に対して `RedisSubscriptionChangeHandler` をオプションで提供して、それぞれのライフサイクルイベントを処理できます。

```swift
// creates 2 subscriptions, one for each given channel
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // do something with the message
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```
