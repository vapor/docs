# リクエスト {#request}

[`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) オブジェクトは、すべての[ルートハンドラ](../basics/routing.md)に渡されます。

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

これは、Vaporの他の機能への主要な窓口です。[リクエストボディ](../basics/content.md)、[クエリパラメータ](../basics/content.md#query)、[ロガー](../basics/logging.md)、[HTTPクライアント](../basics/client.md)、[Authenticator](../security/authentication.md)などのAPIが含まれています。リクエストを通じてこれらの機能にアクセスすることで、計算を適切なイベントループ上に保ち、テスト用にモック化することができます。拡張機能を使用して、独自の[サービス](../advanced/services.md)を`Request`に追加することもできます。

`Request`の完全なAPIドキュメントは[こちら](https://api.vapor.codes/vapor/documentation/vapor/request)で確認できます。

## アプリケーション {#application}

`Request.application`プロパティは、[`Application`](https://api.vapor.codes/vapor/documentation/vapor/application)への参照を保持しています。このオブジェクトには、アプリケーションのすべての設定とコア機能が含まれています。そのほとんどは、アプリケーションが完全に起動する前の`configure.swift`でのみ設定されるべきであり、低レベルAPIの多くはほとんどのアプリケーションでは必要ありません。最も便利なプロパティの1つは`Application.eventLoopGroup`で、新しい`EventLoop`が必要なプロセスのために`any()`メソッドを介して`EventLoop`を取得するために使用できます。また、[`Environment`](../basics/environment.md)も含まれています。

## ボディ {#body}

リクエストボディに`ByteBuffer`として直接アクセスしたい場合は、`Request.body.data`を使用できます。これは、リクエストボディからファイルへのデータのストリーミング（ただし、この場合はリクエストの[`fileio`](../advanced/files.md)プロパティを使用すべきです）や、別のHTTPクライアントへの転送に使用できます。

## クッキー {#cookies}

クッキーの最も便利な用途は組み込みの[セッション](../advanced/sessions.md#configuration)を経由することですが、`Request.cookies`を介してクッキーに直接アクセスすることもできます。

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## ヘッダー {#headers}

`HTTPHeaders`オブジェクトは`Request.headers`でアクセスできます。これには、リクエストとともに送信されたすべてのヘッダーが含まれています。例えば、`Content-Type`ヘッダーにアクセスするために使用できます。

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

`HTTPHeaders`の詳細なドキュメントは[こちら](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders)を参照してください。Vaporは、最もよく使用されるヘッダーの操作を簡単にするために、`HTTPHeaders`にいくつかの拡張機能も追加しています。リストは[こちら](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)で確認できます。

## IPアドレス {#ip-address}

クライアントを表す`SocketAddress`は`Request.remoteAddress`を介してアクセスでき、ログ記録やレート制限のために文字列表現`Request.remoteAddress.ipAddress`を使用すると便利です。アプリケーションがリバースプロキシの背後にある場合、クライアントのIPアドレスを正確に表していない可能性があります。

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

`SocketAddress`の詳細なドキュメントは[こちら](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress)を参照してください。