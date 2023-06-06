# Content

Mit Content können wir den Inhalt und die Zeichenfolge einer Serveranfrage an einen vordefiniertes Datenobjekt binden.

## Grundlagen

Um das Ganze besser zu verstehen, werfen wir einen Blick auf den Aufbau einer solchen Serveranfrage.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Die Angaben _content-type_ und _application/json_ weisen daraufhin, dass die Anfrage JSON-Daten behinhaltet. 

## Binden des Inhalts

Für das Binden der Inhalts müssen wir eine Struktur vom Typ *Codable* anlegen. Indem wir das Objekt mit dem Protokoll *Content* versehen, werden neben den Bindungsmethoden, der Typ vererbt.

```swift
struct Greeting: Content {
    var hello: String
}
```

Über die Eigenschaft *content* kannst du die Methode *decode(_:)* verwendet, um den Inhalt an das eben erstelle Objekt zu binden.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

Die Methode *decode(_:)* benutzt die Angabe *Content-Type* in der Serveranfrage um den passenden *Decoder* aufzurufen. Sollte kein passender *Decoder* gefunden werden oder die Anfrage keine Angaben zum Content-Type besitzen, wird der Fehler 415 (415 Unsupported Media Type) zurückgeliefert.

### Unterstützte Medien

Folgende Medien werden unterstützt:

|Bezeichnung     |header value                     |Typ              |
|----------------|---------------------------------|-----------------|
|JSON            |application/json                 |`.json`          |
|Multipart       |multipart/form-data              |`.formData`      |
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext       |text/plain                       |`.plainText`     |
|HTML            |text/html                        |`.html`          |

Nicht alle Medien werden von _Codable_ unterstützt. Beispielweise unterstützt JSON keinen Top-Level-Fragments oder Plaintext unterstützt keinen nested-data.

## Binden der Zeichenfolge

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Ähnlich wie beim Binden des Inhalts müssen wir eine Struktur anlegen und es mit dem Protokoll *Content* versehen. Zusätzlich müssen wir die Eigenschaft *name* als optional deklarieren, da Parameter in der Zeichenfolge immer optional sind.

```swift
struct Hello: Content {
    var name: String?
}
```

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Zudem kannst du mit Vapor Einzelwerten aus der Zeichenabfolge ziehen:

```swift
app.get("hello") { req -> String in 
    let name: String? = req.query["name"]
    ...
}
```

## Hooks

Vapor ruft automatisch die Methoden _beforeEncode_ und _afterDecode_ eines Objectes von Typ _Content_ auf. Die Methoden sind zwar standardmäßig leer, aber können für benutzerdefinierte Abfolgen überschrieben werden.

```swift
// Runs after this Content is decoded. `mutating` is only required for structs, not classes.
mutating func afterDecode() throws {
    // Name may not be passed in, but if it is, then it can't be an empty string.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Runs before this Content is encoded. `mutating` is only required for structs, not classes.
mutating func beforeEncode() throws {
    // Have to *always* pass a name back, and it can't be an empty string.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## Override Defaults

Der Encoder und Decoder von Vapor kann überschrieben werden.

### Global

`ContentConfiguration.global` lets you change the encoders and decoders Vapor uses by default. This is useful for changing how your entire application parses and serializes data.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Mutating `ContentConfiguration` is usually done in `configure.swift`. 

### Manuelle Bindung

Calls to encoding and decoding methods like `req.content.decode` support passing in custom coders for one-off usages.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Benutzerdefinierte Bindung

Applications and third-party packages can add support for media types that Vapor does not support by default by creating custom coders.

Du kannst einen eigenen Coder erstellen 

### Inhalt

Vapor specifies two protocols for coders capable of handling content in HTTP message bodies: `ContentDecoder` and `ContentEncoder`.

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

Conforming to these protocols allows your custom coders to be registered to `ContentConfiguration` as specified above.

### Zeichenfolge

Vapor specifies two protocols for coders capable of handling content in URL query strings: `URLQueryDecoder` and `URLQueryEncoder`.

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

Conforming to these protocols allows your custom coders to be registered to `ContentConfiguration` for handling URL query strings using the `use(urlEncoder:)` and `use(urlDecoder:)` methods.

### Custom `ResponseEncodable`

Another approach involves implementing `ResponseEncodable` on your types. Consider this trivial `HTML` wrapper type:

```swift
struct HTML {
  let value: String
}
```

Then its `ResponseEncodable` implementation would look like this:

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

If you're using `async`/`await` you can use `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Note that this allows customizing the `Content-Type` header. See [`HTTPHeaders` reference](https://api.vapor.codes/vapor/main/Vapor/) for more details.

You can then use `HTML` as a response type in your routes:

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