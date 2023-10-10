# Routing

ルーティングは、入ってきたリクエストに対して適切なリクエストハンドラを見つける処理です。Vapor のルーティングの核心には、[RoutingKit](https://github.com/vapor/routing-kit) からの高性能なトライノードルータがあります。

## 概要

Vapor でのルーティングの仕組みを理解するために、まず HTTP リクエストの基本について理解する必要があります。以下のサンプルリクエストを見てください。

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

これは、URL `/hello/vapor` への単純な `GET` HTTP リクエストです。この HTTP リクエストは、ブラウザを以下の URL に向けた場合に実行されるものです。

```
http://vapor.codes/hello/vapor
```

### HTTP メソッド

リクエストの最初の部分は HTTP メソッドです。`GET` は最も一般的な HTTP メソッドですが、頻繁に使用されるいくつかの HTTP メソッドがあります。これらの HTTP メソッドは、しばしば [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) セマンティクスと関連付けられています。

|Method|CRUD|
|-|-|
|`GET`|読む(Read)|
|`POST`|作成(Create)|
|`PUT`|置換(Replace)|
|`PATCH`|更新(Update)|
|`DELETE`|削除(Delete)|

### リクエストパス

HTTP メソッドの直後には、リクエストの URI があります。これは、`/` で始まるパスと、`?` の後のオプションのクエリ文字列で構成されています。HTTP メソッドとパスは、Vapor がリクエストをルーティングするために使用するものです。

After the URI is the HTTP version followed by zero or more headers and finally a body. Since this is a `GET` request, it does not have a body.
URI の後には HTTP バージョン、0個以上のヘッダが続き、最後にボディが続きます。これは `GET` リクエストなので、ボディはありません。

### ルーターメソッド

このリクエストが Vapor でどのように処理されるか見てみましょう。

```swift
app.get("hello", "vapor") { req in
    return "Hello, vapor!"
}
```

全ての一般的な HTTP メソッドは、`Application` 上で利用可能としてメソッドが提供されています。リクエストのパスを `/` で区切った 1 つ以上の文字列引数を受け取ります。

また、メソッドの後に `on` を使用して、このように書くこともできます。

```swift
app.on(.GET, "hello", "vapor") { ... }
```

このルートが登録されていると、上記のサンプル HTTP リクエストは、以下の HTTP レスポンスをもたらします。

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### ルートパラメータ

HTTP メソッドとパスに基づいてリクエストを正常にルーティングしたので、次にパスを動的にしてみましょう。"vapor" の名前がパスとレスポンスの両方でハードコードされていることに注意してください。これを動的にして、`/hello/<任意の名前>` にアクセスすると、レスポンスが返されるようにしてみましょう。

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

":" で始まるパスコンポーネントを使用することで、これが動的なコンポーネントであることをルータに示しています。ここで提供される任意の文字列は、このルートにマッチするようになります。その後、`req.parameters` を使用して、文字列の値にアクセスできます。

もう一度サンプルのリクエストを実行すると、まだ vapor に挨拶するレスポンスが返されます。しかし、今度は `/hello/` の後に任意の名前を含めて、それがレスポンスに含まれることを確認できます。 `/hello/swift` を試してみましょう。

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

基本を理解したところで、各セッションをチェックし、パラメータやグループなどについて詳しく学んでください。

## ルート

ルートは、特定の HTTP メソッドと URI パスに対するリクエストハンドラを指定します。また、追加のメタデータを格納することもできます。

### メソッド

ルートは、様々な HTTP メソッドヘルパーを使用して、`Application` に直接登録できます。

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

ルートハンドラは、`ResponseEncodable` であるものを返すことをサポートしています。これには `Content` 、`async` クロージャ、および未来の値が `ResponseEncodable` である `EventLoopFuture` が含まれます。

コンパイラが戻り値のタイプを決定できない状況で、ルートの戻り値のタイプを指定するには、 `in` の前に `-> T` を使用します。

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

これらは、サポートされているルートヘルパーメソッドです:

- `get`
- `post`
- `patch`
- `put`
- `delete`

HTTP メソッドヘルパーに加えて、HTTP メソッドを入力パラメータとして受け入れる `on` 関数があります。

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### パスコンポーネント

各ルート登録メソッドは、`PathComponent` の多様なリストを受け入れます。このタイプは文字列リテラルによって表現可能であり、4つのケースがあります:

- 定数 (`foo`)
- パラーメータ (`:foo`)
- Anything (`*`)
- キャッチオール (`**`)

#### 定数

これは静的なルートコンポーネントです。この位置で正確に一致する文字列のみが許可されます。

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### パラメータ

これは動的なルートコンポーネントです。この位置での任意の文字列が許可されます。パラメータコンポーネントは `:` 接頭辞で指定されます。`:` に続く文字列は、パラメータの名前として使用されます。後でリクエストからパラメータの値にアクセスするために名前を使用できます。

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Anything

これはパラメータと非常に似ていますが、値は破棄されます。このコンポーネントは、単に `*` として指定されます。

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### キャッチオール

これは、1つ以上のコンポーネントに一致する動的なルートコンポーネントです。 `**` だけで指定します。この位置以降の文字列はリクエストでマッチします。

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in
    ...
}
```

### パラメータ

パラメータパスコンポーネント(`:` で接頭辞されたもの) を使用すると、その位置の URI の値が `req.parameters` に格納されます。パスコンポーネントの名前を使用して、値にアクセスできます。

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    ルートパスに `:name` が含まれているので、`rep.parameters.get` が `nil` を返すことはないと核心しています。ただし、ミッドウェア内でルートパラメータにアクセスしたり、複数のルートによってトリガされるコード内でこれを行う場合は、`nil` の可能性を処理する必要があります。

!!! tip
    URL クエリパラメータを取得したい場合、例えば `/hello/?name=foo` 、URLのクエリ文字列で URL エンコードされたデータを処理するために、Vapor の Content API を使用する必要があります。詳しくは[`Content` リファレンス](content.md)を参照してください。

`req.parameters.get` は、パラメータを自動的に `LosslessStringConvertible` タイプにキャストすることもサポートしています。

```swift
// responds to GET /number/42
// responds to GET /number/1337
// ...
app.get("number", ":x") { req -> String in
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

Catchall (`**`) によって一致した URI の値は、`req.parameters` に `[String]` として格納されます。これらのコンポーネントにアクセスするには、 `req.parameters.getCatchall` を使用します。

```swift
// responds to GET /hello/foo
// responds to GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body ストリーミング

`on` メソッドを使用してルートを登録するとき、リクエストの本文がどのように処理されるかを指定できます。デフォルトでは、ハンドラを呼び出す前にリクエストの本文がメモリに収集されます。これは、アプリケーションが非同期に適切なリクエストを読み取るにもかかわらず、リクエストのコンテンツの複号化を同期的に行うために便利です。

デフォルトでは、Vapor はストリーミング本文の収集を 16KB までに制限します。これは `app.routes` を使用して設定できます。

```swift
// Increases the streaming body collection limit to 500kb
app.routes.defaultMaxBodySize = "500kb"
```

収集されるストリーミングボディが設定された制限を超えた場合、`413 Payload Too Large` エラーが投げられる。

個々のルートに対してリクエストボディの収集ストラテジーを設定するには、`body` パラメータを使います。

```swift
// Collects streaming bodies (up to 1mb in size) before calling this route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Handle request.
}
```

`collect` に `maxSize` が渡されると、そのルートのアプリケーションのデフォルトを上書きします。アプリケーションのデフォルトを使用するには、`maxSize` 引数を省略します。

大きなリクエスト、例えばファイルのアップロードの場合、リクエスト本文をバッファに収集すると、システムのメモリが逼迫する可能性があります。リクエスト本文が収集されないようにするには、`stream` 戦略を使用します。

```swift
// Request body will not be collected into a buffer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

リクエストの本文がストリームされる場合、`req.body.data` は `nil` になります。各チャンクがルートに送信されるたびに `req.body.drain` を使用して処理する必要があります。

### 大文字・小文字を区別しないルーティング

ルーティングのデフォルトの振る舞いは、大文字・小文字を区別するとともに、大文字・小文字を保持します。`Constant` パスのコンポーネントは、ルーティングの目的のために、大文字・小文字を区別しないが大文字・小文字を保持する方法で扱うことができます。この振る舞いを有効にするには、アプリケーションの起動前に設定して下さい。：
```swift
app.routes.caseInsensitive = true
```
元のリクエストに変更は加えられません。ルートハンドラは、リクエストのパスコンポーネントを変更せずに受け取ります。


### ルートの表示

アプリケーションのルートにアクセスするには、`Routes` サービスを使用するか、`app.routes` を使用します。

```swift
print(app.routes.all) // [Route]
```

Vapor には `routes` コマンドも同梱されており、利用可能な全てのルートを ASCII 形式のタブで表示してくれます。

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### メタデータ

すべてのルート登録メソッドは、作成された `Route` を返します。これにより、ルートの`userInfo` 辞書にメタデータを追加できます。説明を追加するようなデフォルトのメソッドも用意されています。

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## ルートグループ

ルートのグループ化により、パスの接頭辞または特定のミドルウェアを持つルートのセットを作成できます。グループ化は、ビルダーとクロージャベースの構文をサポートしています。

すべてのグループ化メソッドは `RouteBuilder` を返します。つまり、グループを他のルート構築メソッドと無限に組み合わせたり、ネストにしたりすることができます。

### パス接頭辞

パス接頭辞付きのルートグループを使用すると、1つ以上のパスコンポーネントをルートグループの先頭に追加できます。

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

`get` や `post` などのメソッドに渡すことができる任意のパスコンポーネントを、`grouped` に渡すことができます。代替として、クロージャベースの構文もあります。

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

パスの接頭辞を持つルートグループをネストすると、CRUD API を簡潔に定義できます。

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### ミッドウェア

パスコンポーネントの接頭辞に、ルートグループにミドルウェアを追加することもできます。

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```


これは特に、異なる認証ミドルウェアでルートのサブセットを保護する場合に便利です。

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## リダイレクト

リダイレクトは、SEO のために古いロケーションを新しいロケーションに転送したり、認証されていないユーザーをログインページにリダイレクトしたり、新しいバージョンの API との広報互換性を維持したりするなど、多くのシナリオで役立ちます。

リクエストをリダイレクトするには、次のようにします：

```swift
req.redirect(to: "/some/new/path")
```

また、リダイレクトのタイプを指定することもできます。例えば、ページを永久にリダイレクトして SEO が正しく更新されるようにするには次のようにします：

```swift
req.redirect(to: "/some/new/path", type: .permanent)
```

異なる `RedirectType` は以下の通りです：

* `.permanent` - **301 Permanent** をリダイレクトします
* `.normal` - **303 see other** をリダイレクトします。これは Vapor デフォルトで、クライアントにリダイレクトを **GET** リクエストでフォローするように指示します。
* `.temporary` - **307 Temporary** をリダイレクトします。これにより、リクエストで使用された HTTP メソッドをクライアントが保持するように支持されます。

> 適切なリダイレクションステータスコードを選択するには、[the full list](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection) をチェックして下さい。
