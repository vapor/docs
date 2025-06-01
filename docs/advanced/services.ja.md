# サービス {#services}

Vaporの`Application`と`Request`は、あなたのアプリケーションやサードパーティパッケージによって拡張できるように構築されています。これらの型に追加される新しい機能は、しばしばサービスと呼ばれます。

## 読み取り専用 {#read-only}

最もシンプルなタイプのサービスは読み取り専用です。これらのサービスは、applicationまたはrequestに追加される計算プロパティやメソッドで構成されます。

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

読み取り専用サービスは、この例の`client`のような既存のサービスに依存できます。拡張機能が追加されると、カスタムサービスはrequestの他のプロパティと同様に使用できます。

```swift
req.myAPI.foos()
```

## 書き込み可能 {#writable}

状態や設定が必要なサービスは、データの保存に`Application`と`Request`のストレージを活用できます。次の`MyConfiguration`構造体をアプリケーションに追加したいとしましょう。

```swift
struct MyConfiguration {
    var apiKey: String
}
```

ストレージを使用するには、`StorageKey`を宣言する必要があります。

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

これは、保存される型を指定する`Value`型エイリアスを持つ空の構造体です。空の型をキーとして使用することで、ストレージ値にアクセスできるコードを制御できます。その型がinternalまたはprivateの場合、あなたのコードのみがストレージ内の関連する値を変更できます。

最後に、`MyConfiguration`構造体を取得・設定するための`Application`への拡張を追加します。

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

拡張機能が追加されると、`myConfiguration`を`Application`の通常のプロパティのように使用できます。

```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## ライフサイクル {#lifecycle}

Vaporの`Application`では、ライフサイクルハンドラーを登録できます。これにより、起動やシャットダウンなどのイベントにフックできます。

```swift
// 起動時にhelloを出力します。
struct Hello: LifecycleHandler {
    // アプリケーション起動前に呼ばれます。
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // アプリケーション起動後に呼ばれます。
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // アプリケーションシャットダウン前に呼ばれます。
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// ライフサイクルハンドラーを追加します。
app.lifecycle.use(Hello())
```

## ロック {#locks}

Vaporの`Application`には、ロックを使用してコードを同期するための便利な機能が含まれています。`LockKey`を宣言することで、コードへのアクセスを同期するための一意の共有ロックを取得できます。

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // 何か処理を行う。
}
```

同じ`LockKey`で`lock(for:)`を呼び出すたびに、同じロックが返されます。このメソッドはスレッドセーフです。

アプリケーション全体のロックには、`app.sync`を使用できます。

```swift
app.sync.withLock {
    // 何か処理を行う。
}
```

## リクエスト {#request}

ルートハンドラーで使用されることを意図したサービスは、`Request`に追加する必要があります。リクエストサービスは、リクエストのロガーとイベントループを使用する必要があります。レスポンスがVaporに返されるときにアサーションが発生しないよう、リクエストが同じイベントループに留まることが重要です。

サービスが作業を行うためにリクエストのイベントループを離れる必要がある場合は、終了前にイベントループに戻るようにする必要があります。これは`EventLoopFuture`の`hop(to:)`を使用して行うことができます。

設定などのアプリケーションサービスへのアクセスが必要なリクエストサービスは、`req.application`を使用できます。ルートハンドラーからアプリケーションにアクセスする際は、スレッドセーフティを考慮することに注意してください。一般的に、リクエストでは読み取り操作のみを実行すべきです。書き込み操作はロックで保護する必要があります。