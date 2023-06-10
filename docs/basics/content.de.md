# Modelbindung

Mit der Modelbindung können wir den Inhalt oder die Zeichenfolge einer Serveranfrage an einen vordefiniertes Datenobjekt binden.

## Grundlagen

Um das Binden besser zu verstehen, werfen wir einen kurzen Blick auf den Aufbau einer solchen Serveranfrage.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Die Angabe _content-type_ in der Kopfzeile gibt Aufschluss über die Art des Inhaltes der Anfrage. Vapor nutzt die Angabe um den richtigen Kodierer zum Binden zu finden.

Im Beispiel können wir erkennen, dass es sich bei dem Inhalt um JSON-Daten handelt.

## Binden des Inhalts

Zum Binden des Inhalts müssen wir zuerst eine Struktur vom Typ *Codable* anlegen. Indem wir das Objekt mit Vapor's Protokoll *Content* versehen, werden neben den eigentlichen Bindungsmethoden, der Typ mitvererbt.

```swift
struct Greeting: Content {
    var hello: String
}
```

Über die Eigenschaft *content* können wir anschließend die Methode *decode(_:)* verwenden.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

Die Methode *decode(_:)* benutzt die entsprechende Angabe in der Serveranfrage um den passenden Kodierer aufzurufen.

Sollte kein passender Kodierer gefunden werden oder die Anfrage keine Angaben zum Inhalt besitzen, wird der Fehler 415 (415 Unsupported Media Type) zurückgeliefert.

### Unterstützte Medien

Folgende Medien werden von Vapor standardmäßig unterstützt:

|Bezeichnung     |Feldwert                    |Typ              |
|----------------|---------------------------------|-----------------|
|JSON            |application/json                 |`.json`          |
|Multipart       |multipart/form-data              |`.formData`      |
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext       |text/plain                       |`.plainText`     |
|HTML            |text/html                        |`.html`          |

_Codable_ unterstützt leider nicht alle Medien. 

## Binden der Zeichenfolge

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Ähnlich wie beim Binden des Inhalts müssen wir für das Binden der Zeichenfolge eine Struktur anlegen und es mit dem Protokoll *Content* versehen. 

Zusätzlich müssen wir die Eigenschaft *name* als optional deklarieren, da Parameter in einer Zeichenfolge immer optional sind.

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

Zudem können wir auch Einzelwerte aus der Zeichenabfolge abrufen:

```swift
app.get("hello") { req -> String in 
    let name: String? = req.query["name"]
    ...
}
```

## Hooks

Vapor ruft automatisch jeweils die beiden Methoden _beforeEncode_ und _afterDecode_ eines Objektes von Typ _Content_ auf. 

Die Methoden sind standardmäßig funktionslos, können aber im Bedarfsfall überschrieben werden.

```swift
// Runs before this Content is encoded. `mutating` is only required for structs, not classes.
mutating func beforeEncode() throws {

    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}

// Runs after this Content is decoded. `mutating` is only required for structs, not classes.
mutating func afterDecode() throws {

    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}
```

## Standard überschreiben

Vapor's Standardkodierer kann global oder situationsabhängig überschrieben werden.

### Global

Für eine globale Verwendung eines eigenen Kodierer müssen wir ihn der _ContentConfiguration.global_ mitgeben.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

### Situationsabhängig

Wir können aber auch den Bindungsmethoden abhängig von der Situation einen Kodierer mitgeben.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Benutzerdefinierte Kodierer

### Kodierer für Inhalt

Vapor hat die folgenden zwei Protokolle zum Binden von Inhalt vordefiniert.

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

Indem wir einen unseren eigenen Kodierer mit diese beiden Protokolle versehen, kann er von _ContentConfiguration_ entgegengenommen werden.

### Kodierer für Zeichenfolge

Für das Binden einer Zeichenabfolge hat Vapor die folgenden zwei Protokolle vordefiniert.

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

### `ResponseEncodable`

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