# Logging 

Vapor の Logging API は [SwiftLog](https://github.com/apple/swift-log) を基に構築されています。これは、Vapor が SwiftLog の[バックエンド実装](https://github.com/apple/swift-log#backends)と互換性があることを示しています。

## Logger

`Logger` のインスタンスはログメッセージを出力するために使用されます。Vapor は Logger にアクセスするためのいくつかの簡単な方法を提供しています。

### Request

各入力 `Request` には、そのリクエストに固有のログを使用するためのユニークな Logger があります。

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

リクエスト Logger には、ログの追跡を容易にするために、入力リクエストを識別するユニークな UUID が含まれています。

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
    Logger メタデータは、デバッグログレベルまたはそれ以下でのみ表示されます。

### Application

アプリの起動や設定中のログメッセージには、`Application` の Logger を使用します。

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Custom Logger

`Application` や `Request` にアクセスできない状況では、新しい `Logger` を初期化できます。

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

カスタム Logger は設定された Logging バックエンドに出力されますが、リクエスト UUID のような重要なメタデータは付加されません。可能な限りリクエストやアプリケーション固有の Logger を使用してください。

## Level

SwiftLog はいくつかの異なるログレベルをサポートしています。

|nama|description|
|-|-|
|trace|プログラムの実行を追跡する際に通常のみ役立つ情報を含むメッセージに適しています。|
|debug|プログラムをデバッグする際に通常のみ役立つ情報を含むメッセージに適しています。|
|info|情報メッセージに適しています。|
|notice|エラー条件ではないが、特別な処理が必要な条件に適しています。|
|warning|エラー条件ではないが、noticeよりも重大なメッセージに適しています。|
|error|エラー条件に適しています。|
|critical|通常は直ちに注意が必要な重大なエラー条件に適しています。|

`critical` メッセージがログに記録されると、ログバックエンドはシステム状態をキャプチャするために重い操作（スタックトレースのキャプチャなど）を自由に実行できます。

デフォルトでは、Vapor は `info` レベルのログを使用します。`production` 環境で実行する場合は、パフォーマンス向上のためにnoticeが使用されます。

### Log Level の変更

環境モードに関係なく、ログの量を増減するためにログレベルをオーバーライドできます。

最初の方法は、アプリケーションを起動する際にオプションの `--log` フラグを渡すことです。

```sh
swift run App serve --log debug
```

2番目の方法は、`LOG_LEVEL` 環境変数を設定することです。

```sh
export LOG_LEVEL=debug
swift run App serve
```

これらの操作は、Xcodeで `App` スキームを編集することで行うことができます。

## 設定

SwiftLog は、プロセスごとに一度 `LoggingSystem` をブートストラップすることによって設定されます。Vapor プロジェクトでは、これは通常 `entrypoint.swift` で行われます。

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` は、コマンドライン引数や環境変数に基づいてデフォルトのログハンドラーを設定するために Vapor が提供するヘルパーメソッドです。デフォルトのログハンドラーは、ANSI カラーサポートを備えた端末へのメッセージ出力をサポートしています。

### カスタムハンドラー

Vaporのデフォルトのログハンドラーをオーバーライドし、独自のものを登録することができます。

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

SwiftLog がサポートするすべてのバックエンドは Vapor と互換性があります。ただし、コマンドライン引数や環境変数を使用したログレベルの変更は、Vapor のデフォルトのログハンドラーとのみ互換性があります。
