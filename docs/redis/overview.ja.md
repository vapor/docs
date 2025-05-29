# Redis

[Redis](https://redis.io/)は、キャッシュやメッセージブローカーとして一般的に使用される、最も人気のあるインメモリデータ構造ストアの1つです。

このライブラリは、VaporとRedisとの通信を行う基盤ドライバーである[**RediStack**](https://github.com/swift-server/RediStack)との統合です。

!!! note
    Redisの機能のほとんどは**RediStack**によって提供されています。
    そのドキュメントに精通することを強くお勧めします。
    
    _適切な箇所にリンクを提供しています。_

## パッケージ {#package}

Redisを使用する最初のステップは、Swiftパッケージマニフェストでプロジェクトの依存関係として追加することです。

> この例は既存のパッケージ用です。新しいプロジェクトの開始に関するヘルプについては、メインの[Getting Started](../getting-started/hello-world.md)ガイドを参照してください。

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

## 設定 {#configure}

Vaporは[`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection)インスタンスのプーリング戦略を採用しており、個々の接続とプール自体を設定するためのいくつかのオプションがあります。

Redisを設定するために必要な最小限の要件は、接続するURLを提供することです：

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Redis設定 {#redis-configuration}

> APIドキュメント：[`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Redisインスタンスのクラスターなど、複数のRedisエンドポイントがある場合は、代わりにイニシャライザに渡す[`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress)コレクションを作成する必要があります。

`SocketAddress`を作成する最も一般的な方法は、[`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:))静的メソッドを使用することです。

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

単一のRedisエンドポイントの場合、`SocketAddress`の作成を処理してくれるため、便利なイニシャライザを使用する方が簡単です：

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (`String`または[`Foundation.URL`](https://developer.apple.com/documentation/foundation/url)を使用)
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Redisインスタンスがパスワードで保護されている場合は、`password`引数として渡す必要があります。

各接続は作成時にパスワードを使用して認証されます。

#### database

これは、各接続が作成されるときに選択したいデータベースインデックスです。

これにより、自分でRedisに`SELECT`コマンドを送信する必要がなくなります。

!!! warning
    データベースの選択は維持されません。自分で`SELECT`コマンドを送信する際は注意してください。

### 接続プールオプション {#connection-pool-options}

> APIドキュメント：[`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note
    ここでは最も一般的に変更されるオプションのみを強調しています。すべてのオプションについては、APIドキュメントを参照してください。

#### minimumConnectionCount

これは、各プールが常に維持したい接続数を設定する値です。

値が`0`の場合、何らかの理由で接続が失われても、プールは必要になるまで再作成しません。

これは「コールドスタート」接続として知られており、最小接続数を維持するよりもオーバーヘッドがあります。

#### maximumConnectionCount

このオプションは、最大接続数がどのように維持されるかの動作を決定します。

!!! seealso
    どのようなオプションが利用可能かについては、`RedisConnectionPoolSize` APIを参照してください。

## コマンドの送信 {#sending-a-command}

[`Application`](https://api.vapor.codes/vapor/documentation/vapor/application)または[`Request`](https://api.vapor.codes/vapor/documentation/vapor/request)インスタンスの`.redis`プロパティを使用してコマンドを送信できます。これにより、[`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient)にアクセスできます。

すべての`RedisClient`には、さまざまな[Redisコマンド](https://redis.io/commands)用の拡張機能があります。

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// または

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### サポートされていないコマンド {#unsupported-commands}

**RediStack**が拡張メソッドでコマンドをサポートしていない場合でも、手動で送信できます。

```swift
// コマンドの後の各値は、Redisが期待する位置引数です
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// または

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Pub/Subモード {#pub-sub-mode}

Redisは、接続が特定の「チャンネル」をリッスンし、購読したチャンネルが「メッセージ」（何らかのデータ値）をパブリッシュしたときに特定のクロージャを実行できる[「Pub/Sub」モード](https://redis.io/topics/pubsub)をサポートしています。

サブスクリプションには定義されたライフサイクルがあります：

1. **subscribe**：サブスクリプションが最初に開始されたときに1回呼び出されます
1. **message**：購読したチャンネルにメッセージがパブリッシュされるたびに0回以上呼び出されます
1. **unsubscribe**：リクエストによるか接続が失われたかにより、サブスクリプションが終了したときに1回呼び出されます

サブスクリプションを作成するときは、購読したチャンネルによってパブリッシュされたすべてのメッセージを処理するために、少なくとも[`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver)を提供する必要があります。

オプションで、それぞれのライフサイクルイベントを処理するために、`onSubscribe`と`onUnsubscribe`用の`RedisSubscriptionChangeHandler`を提供できます。

```swift
// 指定された各チャンネルに対して1つずつ、2つのサブスクリプションを作成します
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // メッセージで何か処理を行う
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("unsubscribed from \(channel)")
    print("subscriptions remaining: \(subscriptionCount)")
  }
```