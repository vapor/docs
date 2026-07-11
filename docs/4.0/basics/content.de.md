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

Das bedeutet, dass diese Route automatisch auch alle anderen unterstützten Content-Typen akzeptiert, wie zum Beispiel URL-Encoded Form:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

Im Falle von Datei-Uploads muss die entsprechende Eigenschaft vom Typ `Data` sein:

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Unterstützte Medien

Folgende Medien werden von Vapor standardmäßig unterstützt:

|Bezeichnung     |Feldwert                    |Typ              |
|----------------|---------------------------------|-----------------|
|JSON            |application/json                 |`.json`          |
|Multipart       |multipart/form-data              |`.formData`      |
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext       |text/plain                       |`.plainText`     |
|HTML            |text/html                        |`.html`          |

_Codable_ unterstützt leider nicht alle Medien vollständig. So unterstützt JSON zum Beispiel keine Fragmente auf oberster Ebene und Plaintext unterstützt keine verschachtelten Daten.

## Binden der Zeichenfolge

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Ähnlich wie beim Binden des Inhalts müssen wir für das Binden der Zeichenfolge eine Struktur anlegen und es mit dem Protokoll *Content* versehen. 

Zusätzlich müssen wir die Eigenschaft *name* als optional deklarieren, da Parameter in einer Zeichenfolge immer optional sind. Soll ein Parameter zwingend erforderlich sein, sollte stattdessen ein Routenparameter verwendet werden.

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

Diese Route würde bei der obigen Beispielanfrage zu folgender Antwort führen:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Wird die Zeichenfolge weggelassen, wie in der folgenden Anfrage, wird stattdessen der Name "Anonymous" verwendet:

```http
GET /hello HTTP/1.1
content-length: 0
```

Zudem können wir auch Einzelwerte aus der Zeichenabfolge abrufen:

```swift
let name: String? = req.query["name"]
```

## Hooks

Vapor ruft automatisch jeweils die beiden Methoden _beforeEncode_ und _afterDecode_ eines Objektes von Typ _Content_ auf. 

Die Methoden sind standardmäßig funktionslos, können aber im Bedarfsfall überschrieben werden.

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

## Standard überschreiben

Vapor's Standardkodierer kann global oder situationsabhängig überschrieben werden.

### Global

Für eine globale Verwendung eines eigenen Kodierer müssen wir ihn der _ContentConfiguration.global_ mitgeben. Das ist nützlich, wenn wir ändern möchten, wie die gesamte Anwendung Daten verarbeitet und serialisiert.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Das Anpassen der `ContentConfiguration` erfolgt üblicherweise in `configure.swift`.

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

Indem wir einen eigenen Kodierer mit diesen beiden Protokollen versehen, kann er über die Methoden `use(urlEncoder:)` und `use(urlDecoder:)` bei der `ContentConfiguration` für das Verarbeiten von URL-Zeichenfolgen registriert werden.

### Benutzerdefinierte `ResponseEncodable`

Ein weiterer Ansatz besteht darin, `ResponseEncodable` für die eigenen Typen zu implementieren. Betrachten wir dazu diesen einfachen `HTML`-Wrapper-Typ:

```swift
struct HTML {
  let value: String
}
```

Die entsprechende `ResponseEncodable`-Implementierung würde dann so aussehen:

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

Wenn wir `async`/`await` verwenden, können wir stattdessen `AsyncResponseEncodable` nutzen:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Beachte, dass dies auch das Anpassen des `Content-Type`-Headers erlaubt. Weitere Details finden sich in der [`HTTPHeaders`-Referenz](https://api.vapor.codes/vapor/documentation/vapor/response/headers).

Anschließend können wir `HTML` als Antworttyp in unseren Routen verwenden:

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