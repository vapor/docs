# エラー

Vapor は Swift の `Error` プロトコルをベースにしたエラー処理を採用しています。ルートハンドラは、エラーを `throw` するか、失敗した `EventLoopFuture` を返すことができます。Swiftの `Error` を throw するか返すと、`500` ステータスのレスポンスが生成され、エラーがログに記録されます。`AbortError` と `DebuggableError` は、それぞれ結果として得られるレスポンスとログを変更するために使用できます。エラーの処理は `ErrorMiddleware` によって行われます。このミドルウェアはデフォルトでアプリケーションに追加されており、必要に応じてカスタムロジックに置き換えることができます。

## Abort

Vapor は `Abort` というデフォルトのエラー構造体を提供しています。この構造体は `AbortError` と `DebuggableError` の両方に準拠しています。HTTP ステータスとオプショナルな失敗理由を指定して初期化できます。

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

非同期の状況で throw がサポートされていない場合や `EventLoopFuture` を返す必要がある場合、例えば `flatMap` クロージャ内で、失敗した未来を返すことができます。

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor にはオプショナルな値を持つ未来をアンラップするためのヘルパーエクステンション `unwrap(or:)` が含まれています。

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Non-optional User supplied to closure.
}
```

`User.find` が `nil` を返した場合、提供されたエラーで未来が失敗します。それ以外の場合は、`flatMap` に非オプショナルな値が提供されます。`async` / `await` を使用している場合は、通常どおりオプショナルを扱うことができます：

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

デフォルトでは、ルートクロージャによって throw されたり返されたりする任意の Swift の Error は `500 Internal Server Error` レスポンスになります。デバッグモードでビルドされた場合、`ErrorMiddleware` はエラーの説明を含めます。セキュリティ上の理由から、リリースモードでビルドするとこれが除去されます。

特定のエラーの結果として得られる `HTTP` レスポンスステータスや理由を設定するには、それを `AbortError` に準拠させます。

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## Debuggable Error

`ErrorMiddleware` は、ルートによって throw されたエラーのログを記録するために `Logger.report(error:)` メソッドを使用します。このメソッドは `CustomStringConvertible` や `LocalizedError` などのプロトコルへの準拠をチェックし、読みやすいメッセージをログに記録します。

エラーログをカスタマイズするために、エラーを `DebuggableError` に準拠させることができます。このプロトコルには、固有の識別子、ソースの位置、スタックトレースなど、多くの便利なプロパティが含まれています。これらのプロパティのほとんどはオプショナルであるため、準拠を採用するのは容易です。

`DebuggableError` に最適に準拠するためには、エラーは構造体であるべきです。これにより、必要に応じてソースとスタックトレース情報を格納できます。以下は、前述の `MyError` 列挙型を構造体に更新し、エラーソース情報をキャプチャする例です。

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` には、エラーのデバッグ性を向上させるために使用できる `possibleCauses` や `suggestedFixes` など、他にもいくつかのプロパティがあります。より詳細に知りたい場合は、プロトコル自体をご覧ください。

## スタックトレース

Vaporは、通常のSwiftエラーやクラッシュに対するスタックトレースの表示をサポートしています。

### Swift バックトレース

Vapor は、Linux 上で致命的なエラーやアサーションの後にスタックトレースを提供するために、[SwiftBacktrace](https://github.com/swift-server/swift-backtrace) ライブラリを使用しています。これが機能するためには、アプリはコンパイル中にデバッグシンボルを含める必要があります。

```sh
swift build -c release -Xswiftc -g
```

### エラートレース

デフォルトでは、`Abort` は初期化されたときに現在のスタックトレースをキャプチャします。カスタムエラータイプは、`DebuggableError` に準拠し、`StackTrace.capture()` を保存することでこれを実現できます。

```swift
import Vapor

struct MyError: DebuggableError {
    var identifier: String
    var reason: String
    var stackTrace: StackTrace?

    init(
        identifier: String,
        reason: String,
        stackTrace: StackTrace? = .capture()
    ) {
        self.identifier = identifier
        self.reason = reason
        self.stackTrace = stackTrace
    }
}
```

アプリケーションの[ログレベル](logging.ja.md#level)が `.debug` 以下に設定されている場合、エラースタックトレースはログ出力に含まれます。

ログレベルが `.debug` より大きい場合、スタックトレースはキャプチャされません。この挙動を変更するには、`configure` 内で `StackTrace.isCaptureEnabled` を手動で設定してください。

```swift
// Always capture stack traces, regardless of log level.
StackTrace.isCaptureEnabled = true
```

## エラーミドルウェア

`ErrorMiddleware` は、デフォルトでアプリケーションに追加される唯一のミドルウェアです。このミドルウェアは、ルートハンドラーによって投げられたり返されたりした Swift のエラーを HTTP レスポンスに変換します。このミドルウェアがない場合、投げられたエラーは応答なしに接続が閉じられることになります。

`AbortError` と `DebuggableError` が提供するものを超えてエラー処理をカスタマイズするには、`ErrorMiddleware` を独自のエラー処理ロジックで置き換えることができます。これを行うには、まず `app.middleware` を空の設定に設定して、デフォルトのエラーミドルウェアを削除します。その後、独自のエラー処理ミドルウェアをアプリケーションに最初のミドルウェアとして追加します。

```swift
// Remove all existing middleware.
app.middleware = .init()
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

エラー処理ミドルウェアの _前に_ 置くべきミドルウェアはほどんどありません。注目すべき例外は `CORSMiddleware` です。
