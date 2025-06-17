# ミドルウェア {#middleware}

ミドルウェアは、クライアントとVaporのルートハンドラーの間にあるロジックチェーンです。これにより、受信リクエストがルートハンドラーに到達する前、および送信レスポンスがクライアントに送信される前に操作を実行できます。

## 設定 {#configuration}

ミドルウェアは、`configure(_:)`内で`app.middleware`を使用してグローバルに（すべてのルートに）登録できます。

```swift
app.middleware.use(MyMiddleware())
```

また、ルートグループを使用して個々のルートにミドルウェアを追加することもできます。

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// このリクエストはMyMiddlewareを通過しています。
}
```

### 順序 {#order}

ミドルウェアが追加される順序は重要です。アプリケーションに入ってくるリクエストは、追加された順序でミドルウェアを通過します。アプリケーションから出ていくレスポンスは、逆の順序でミドルウェアを通過します。ルート固有のミドルウェアは常にアプリケーションミドルウェアの後に実行されます。以下の例を見てください：

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

`GET /hello`へのリクエストは、以下の順序でミドルウェアを通過します：

```
Request → A → B → C → Handler → C → B → A → Response
```

ミドルウェアは先頭に追加することもできます。これは、Vaporが自動的に追加するデフォルトのミドルウェアの前にミドルウェアを追加したい場合に便利です：

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## ミドルウェアの作成 {#creating-a-middleware}

Vaporにはいくつかの便利なミドルウェアが付属していますが、アプリケーションの要件により独自のミドルウェアを作成する必要があるかもしれません。例えば、管理者でないユーザーがルートのグループにアクセスすることを防ぐミドルウェアを作成できます。

> コードを整理するために、`Sources/App`ディレクトリ内に`Middleware`フォルダを作成することをお勧めします

ミドルウェアは、Vaporの`Middleware`または`AsyncMiddleware`プロトコルに準拠する型です。レスポンダーチェーンに挿入され、リクエストがルートハンドラーに到達する前にアクセス・操作し、レスポンスが返される前にアクセス・操作できます。

上記の例を使用して、ユーザーが管理者でない場合にアクセスをブロックするミドルウェアを作成します：

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

または、`async`/`await`を使用している場合は次のように書けます：

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

カスタムヘッダーを追加するなど、レスポンスを変更したい場合も、ミドルウェアを使用できます。ミドルウェアは、レスポンダーチェーンからレスポンスを受け取るまで待機し、レスポンスを操作できます：

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

または、`async`/`await`を使用している場合は次のように書けます：

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## ファイルミドルウェア {#file-middleware}

`FileMiddleware`は、プロジェクトのPublicフォルダからクライアントへのアセットの提供を可能にします。スタイルシートやビットマップ画像などの静的ファイルをここに含めることができます。

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

`FileMiddleware`が登録されると、`Public/images/logo.png`のようなファイルはLeafテンプレートから`<img src="/images/logo.png"/>`としてリンクできます。

サーバーがiOSアプリなどのXcodeプロジェクトに含まれている場合は、代わりに次を使用してください：

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

また、アプリケーションをビルドした後のリソース内でフォルダ構造を維持するために、XcodeでGroupsではなくFolder Referencesを使用してください。

## CORSミドルウェア {#cors-middleware}

Cross-origin resource sharing（CORS）は、Webページ上の制限されたリソースを、最初のリソースが提供されたドメイン以外の別のドメインからリクエストできるようにするメカニズムです。Vaporで構築されたREST APIは、最新のWebブラウザに安全にリクエストを返すためにCORSポリシーが必要です。

設定例は次のようになります：

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// corsミドルウェアは`at: .beginning`を使用してデフォルトのエラーミドルウェアの前に配置する必要があります
app.middleware.use(cors, at: .beginning)
```

スローされたエラーは即座にクライアントに返されるため、`CORSMiddleware`は`ErrorMiddleware`の前にリストされている必要があります。そうでない場合、HTTPエラーレスポンスはCORSヘッダーなしで返され、ブラウザで読み取ることができません。