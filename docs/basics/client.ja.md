# クライアント {#client}

Vapor のクライアント API では、外部のリソースに対して HTTP 通信を行うことができます。これは [async-http-client](https://github.com/swift-server/async-http-client) に基づいており、[コンテンツ](content.ja.md) API と統合されています。

## 概要 {#overview}

`Application` やルートハンドラー内の `Request` から、デフォルトクライアントにアクセスできます。

```swift
app.client // Client

app.get("test") { req in
	req.client // Client
}
```

アプリケーションのクライアントは、設定時に HTTP リクエストを送る際に便利です。ルートハンドラー内で HTTP リクエストを行う場合は、リクエストに紐づくクライアントを使うべきです。

### メソッド {#methods}

`GET` リクエストを行う際には、目的の URL を `get` メソッドに渡します。

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

`get`、`post`、`delete` など、各種 HTTP メソッドに対応したメソッドがあります。クライアントからのレスポンスはFutureとして返され、HTTPステータス、ヘッダー、ボディが含まれます。

### コンテンツ {#content}

Vapor の [コンテンツ](content.ja.md) を使うと、クライアントリクエストやレスポンスのデータを扱うことができます。コンテンツやクエリパラメータをエンコードしたり、ヘッダーを追加するには、`beforeSend` クロージャを使います。

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// リクエストURLにクエリ文字列をエンコードします。
	try req.query.encode(["q": "test"])

	// JSONをリクエストボディにエンコードします。
    try req.content.encode(["hello": "world"])
    
	// リクエストに認証ヘッダーを追加します。
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// レスポンスを処理する。
```

レスポンスボディを `Content` を使ってデコードすることもできます。

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

もし、Future を使っている場合は、`flatMapThrowing` を使うことができます。

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// ここでJSONを使用
}
```

## 設定 {#configuration}

アプリケーションを通じて、基本となる HTTP クライアントを設定することができます。

```swift
// 自動リダイレクトを無効にする。
app.http.client.configuration.redirectConfiguration = .disallow
```

初めてデフォルトクライアントを使用する前に、必ず設定を完了させておく必要があります。
