# コンテンツ {#content}

Vapor のコンテンツ API を使用すると、Codable な構造体を HTTP メッセージに対して簡単にエンコード・デコードできます。標準では [JSON](https://tools.ietf.org/html/rfc7159) 形式でエンコードされており、[URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) や [Multipart](https://tools.ietf.org/html/rfc2388) についても即座に使えるサポートがあります。この API はカスタマイズ可能であり、特定の HTTP コンテンツタイプに対するエンコーディングの戦略を追加したり、変更したり、置き換えたりすることができます。

## 概要 {#overview}

Vapor のコンテンツ API の仕組みを理解するためには、HTTP メッセージの基本について知っておく必要があります。以下にリクエストの例を示します。

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

このリクエストは、`content-type` ヘッダーを通じて `application/json` メディアタイプでJSON形式のデータが含まれていることを示しています。ヘッダーの後のボディ部分には、約束されたJSONデータが続きます。

### コンテンツ構造体 {#content-struct}

この HTTP メッセージをデコードする最初のステップは、期待される構造にマッチする Codable 型を作成することです。

```swift
struct Greeting: Content {
    var hello: String
}
```

型を `Content` に準拠させると、コンテンツ API を扱うための追加ユーティリティが得られると同時に、`Codable` にも自動的に準拠するようになります。

コンテンツの構造ができたら、`req.content` を使ってリクエストからデコードできます。

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

このデコードメソッドは、リクエストのコンテンツタイプに基づいて適切なデコーダーを見つけます。デコーダーが見つからない、またはリクエストにコンテンツタイプヘッダーが含まれていない場合、`415` エラーが発生します。

つまり、このルートは URL エンコードされたフォームなど、他のサポートされているコンテンツタイプも自動的に受け入れるということです。

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

ファイルアップロードのケースでは、コンテンツのプロパティは `Data` 型である必要があります。

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### サポートされるメディアタイプ {#supported-media-types}

以下は、コンテンツ API がデフォルトでサポートしているメディアタイプです。

|name|header value|media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

すべてのメディアタイプが全ての `Codable` 機能をサポートしているわけではありません。例えば、JSON はトップレベルのフラグメントをサポートしておらず、プレーンテキストはネストされたデータをサポートしていません。

## クエリ {#query}

Vapor のコンテンツ API は、URL のクエリ文字列にエンコードされたデータの処理に対応しています。

### デコード {#decoding}

URL クエリ文字列をデコードする方法を理解するために、以下の例をご覧ください。

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

HTTP メッセージのボディ内容を扱う API と同様に、URL クエリ文字列を解析する最初のステップは、期待される構造にあった `struct` を作成することです。

```swift
struct Hello: Content {
    var name: String?
}
```

`name` がオプションな `String` であることに注意して下さい。URL クエリ文字列は常にオプショナルであるべきだからです。パラメーターを必須にしたい場合は、ルートパラメーターを使って下さい。

期待されるクエリ文字列に合わせた `Content` 構造体が用意できたら、それをデコードできます。

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

上記の例のリクエストに基づいて、このルートは次のような応答を返します：

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

例えば、次のリクエストのようにクエリ文字列が省略された場合は、"Anonymous" が使われます。

```http
GET /hello HTTP/1.1
content-length: 0
```

### 単一の値 {#single-value}

`Content` 構造体へのデコードだけでなく、Vapor はクエリ文字列から単一の値を取得することもサポートしています。これはサブスクリプトを使用して行われます。

```swift
let name: String? = req.query["name"]
```

## フック {#hooks}

Vapor は、`Content` タイプに対して `beforeEncode` および `afterDecode` を自動的に呼び出します。デフォルトの実装は何もしませんが、これらのメソッドを使用してカスタムロジックを実行することができます。

```swift
// この Content がデコードされた後に実行されます。`mutating` は構造体のみに必要で、クラスには必要ありません。
mutating func afterDecode() throws {
    // 名前は *必ず* 渡される必要があり、空文字列であってはなりません。
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// この Content がエンコードされる前に実行されます。`mutating` は構造体のみに必要で、クラスには必要ありません。
mutating func beforeEncode() throws {
    // 名前は *必ず* 渡される必要があり、空文字列であってはなりません。
    guard
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines),
        !name.isEmpty
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## デフォルトの上書き {#override-defaults}

Vapor の Content API によって使用されるデフォルトのエンコーダーとデコーダーは設定可能です。

### グローバル {#global}

`ContentConfiguration.global` を使用すると、Vapor がデフォルトで使用するエンコーダーやデコーダーを変更できます。これは、アプリケーション全体でデータの解析やシリアライズ方法を変更するのに便利です。

```swift
// UNIX タイムスタンプの日付を使用する新しい JSON エンコーダーを作成します。
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// `.json` メディアタイプで使用されるグローバルエンコーダーを上書きします。
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

`ContentConfiguration` の変更は通常、`configure.swift` で行われます。

### 1回限り {#one-off}

`req.content.decode` のようなエンコーディングやデコーディングのメソッド呼び出しは、1回限りの使用のためにカスタムコーダーを渡すことをサポートしています。

```swift
// UNIX タイムスタンプの日付を使用する新しい JSON デコーダーを作成します。
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// カスタムデコーダーを使用して Hello 構造体をデコードします。
let hello = try req.content.decode(Hello.self, using: decoder)
```

## カスタムコーダー {#custom-coders}

アプリケーションやサードパーティのパッケージは、Vapor がデフォルトでサポートしていないメディアタイプに対応するためにカスタムコーダーを作成することができます。

### Content {#content}

Vapor は、HTTP メッセージボディのコンテンツを処理するためのコーダーのために、`ContentDecoder` と `ContentEncoder` の2つのプロトコルを指定しています。

```swift
public protocol ContentEncoder {
    func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws
        where E: Encodable
}

public protocol ContentDecoder {
    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D
        where D: Decodable
}
```

これらのプロトコルに準拠することで、カスタムコーダーを上記で指定されたように `ContentConfiguration` に登録できます。

### URL クエリ {#url-query}

Vapor は、URL クエリ文字列のコンテンツを処理することができるコーダーのための 2 つのプロトコルを指定しています: `URLQueryDecoder` と `URLQueryEncoder`

```swift
public protocol URLQueryDecoder {
    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D
        where D: Decodable
}

public protocol URLQueryEncoder {
    func encode<E>(_ encodable: E, to url: inout URI) throws
        where E: Encodable
}
```

これらのプロトコルに準拠することで、`use(urlEncoder:)` および `use(urlDecoder:)` メソッドを使用して、URL クエリ文字列の処理のためにカスタムコーダーを `ContentConfiguration` に登録できます。

### カスタム `ResponseEncodable` {#custom-responseencodable}

別のアプローチには、タイプに `ResponseEncodable` を実装するというものがあります。この単純な `HTML` ラッパータイプを考えてみてください。

```swift
struct HTML {
  let value: String
}
```

その `ResponseEncodable` の実装は以下のようになります。

```swift
extension HTML: ResponseEncodable {
  public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return request.eventLoop.makeSucceededFuture(.init(
      status: .ok, headers: headers, body: .init(string: value)
    ))
  }
}
```

`async`/`await` を使用している場合は、`AsyncResponseEncodable` を使用できます。

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

これにより、`Content-Type` ヘッダーをカスタマイズできることに注意して下さい。詳細は [`HTTPHeaders` リファレンス](https://api.vapor.codes/vapor/documentation/vapor/response/headers) を参照して下さい。

その後、ルート内でレスポンスタイプとして `HTML` を使用できます。

```swift
app.get { _ in
  HTML(value: """
  <html>
    <body>
      <h1>Hello, World!</h1>
    </body>
  </html>
  """)
}
```
