# Content

Met Vapor's content API kunt u eenvoudig Codable structs coderen/decoderen naar / van HTTP berichten. [JSON](https://tools.ietf.org/html/rfc7159) codering wordt standaard gebruikt met out-of-the-box ondersteuning voor [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) en [Multipart](https://tools.ietf.org/html/rfc2388). De API is ook configureerbaar, zodat u encoding strategieën voor bepaalde HTTP-inhoudstypen kunt toevoegen, wijzigen of vervangen.

## Overzicht

Om te begrijpen hoe Vapor's content API werkt, moet u eerst een paar basisbegrippen over HTTP berichten begrijpen. Kijk eens naar het volgende voorbeeld verzoek.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Dit verzoek geeft aan dat het JSON-gecodeerde gegevens bevat met behulp van de `content-type` header en `application/json` media type. Zoals beloofd, volgen er JSON gegevens na de headers in de body.

### Content Struct

De eerste stap bij het decoderen van dit HTTP-bericht is het maken van een Codable-type dat overeenkomt met de verwachte structuur. 

```swift
struct Greeting: Content {
    var hello: String
}
```

Conformeren van het type aan `Content` zal automatisch conformeren aan `Codable` samen met extra hulpprogramma's voor het werken met de content API.

Als je eenmaal de inhoudsstructuur hebt, kun je deze decoderen uit het inkomende verzoek met `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

De decodeer methode gebruikt het inhoudstype van het verzoek om een geschikte decoder te vinden. Als er geen decoder gevonden wordt, of het verzoek bevat geen inhoudstype header, dan wordt er een `415` foutmelding gegeven.

Dat betekent dat deze route automatisch alle andere ondersteunde inhoudstypes accepteert, zoals url-gecodeerde formulieren:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

In het geval van bestand uploads, moet de inhoudseigenschap van het type `Data` zijn

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Ondersteunde Media Types

Hieronder staan de mediatypes die de inhoud-API standaard ondersteunt.

|naam|header waarde|media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Niet alle media types ondersteunen alle `Codable` eigenschappen. Bijvoorbeeld, JSON ondersteunt geen top-level fragmenten en Plaintext ondersteunt geen geneste gegevens.

## Query

Vapor's Content API's ondersteunen het omgaan met URL gecodeerde data in de URL's query string. 

### Decoderen

Om te begrijpen hoe het decoderen van een URL querystring werkt, bekijk eens het volgende voorbeeld verzoek.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Net als de API's voor het verwerken van HTTP bericht inhoud, is de eerste stap voor het parsen van URL query strings het maken van een `struct` die overeenkomt met de verwachte structuur.

```swift
struct Hello: Content {
    var name: String?
}
```

Merk op dat `name` een optionele `String` is, omdat URL query strings altijd optioneel moeten zijn. Als je een parameter wilt verplichten, gebruik dan een route parameter.

Nu dat je een `Content` struct hebt voor de verwachte query string van deze route, kun je deze decoderen.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Deze route zou resulteren in het volgende antwoord, gegeven het voorbeeldverzoek van hierboven:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Als de querystring wordt weggelaten, zoals in het volgende verzoek, wordt in plaats daarvan de naam "Anonymous" gebruikt.

```http
GET /hello HTTP/1.1
content-length: 0
```

### Enkele Waarde

Naast het decoderen naar een `Content` struct, ondersteunt Vapor ook het ophalen van enkele waarden uit de query string met behulp van subscripts.

```swift
let name: String? = req.query["name"]
```

## Hooks

Vapor zal automatisch `beforeEncode` en `afterDecode` aanroepen op een `Content` type. Er zijn standaard implementaties die niets doen, maar je kunt deze methodes gebruiken om aangepaste logica uit te voeren.

```swift
// Wordt uitgevoerd nadat deze inhoud is gedecodeerd. `muteren` is alleen nodig voor structs, niet voor klassen.
mutating func afterDecode() throws {
    // Naam mag niet worden doorgegeven, maar als dat wel het geval is, mag het geen lege string zijn.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Wordt uitgevoerd voordat deze inhoud wordt gecodeerd. `muteren` is alleen nodig voor structs, niet voor klassen.
mutating func beforeEncode() throws {
    // Je moet *altijd* een naam teruggeven, en het mag geen lege string zijn.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## Standaarden Overschrijven

De standaard encoders en decoders die door Vapor's Content API's worden gebruikt, kunnen worden geconfigureerd. 

### Global

Met `ContentConfiguration.global` kunt u de encoders en decoders wijzigen die Vapor standaard gebruikt. Dit is handig om te veranderen hoe uw hele applicatie data parseert en serialiseert.

```swift
// maak een nieuwe JSON encoder die unix-timestamp data gebruikt
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// overschrijf de globale codeur die gebruikt wordt voor het `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Het muteren van `ContentConfiguration` wordt meestal gedaan in `configure.swift`. 

### Eenmalig

Aanroepen van codeer en decodeer methodes zoals `req.content.decode` ondersteunen het doorgeven van aangepaste codeerders voor eenmalig gebruik.

```swift
// maak een nieuwe JSON encoder die unix-timestamp data gebruikt
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodeert Hello struct met behulp van aangepaste decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Aangepaste Coders

Toepassingen en pakketten van derden kunnen ondersteuning toevoegen voor mediatypes die Vapor standaard niet ondersteunt door aangepaste codeerders te maken.

### Content

Vapor specificeert twee protocollen voor codeerders die in staat zijn om inhoud in HTTP berichtlichamen te behandelen: `ContentDecoder` en `ContentEncoder`.

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

Door te voldoen aan deze protocollen kunnen uw aangepaste codeerders worden geregistreerd bij `ContentConfiguration` zoals hierboven gespecificeerd.

### URL Query

Vapor specificeert twee protocollen voor codeerders die in staat zijn om inhoud in URL query strings te verwerken: `URLQueryDecoder` en `URLQueryEncoder`.

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

Door te voldoen aan deze protocollen kunnen uw aangepaste codeerders worden geregistreerd bij `ContentConfiguration` voor het afhandelen van URL query strings met behulp van de `use(urlEncoder:)` en `use(urlDecoder:)` methoden.

### Aangepaste `ResponseEncodable`

Een andere aanpak is het implementeren van `ResponseEncodable` op je types. Beschouw deze triviale `HTML` wrapper type:

```swift
struct HTML {
  let value: String
}
```

Dan zou de `ResponseEncodable` implementatie er als volgt uitzien:

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

Als je `async`/`await` gebruikt, kun je `AsyncResponseEncodable` gebruiken:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Merk op dat dit het mogelijk maakt om de `Content-Type` header aan te passen. Zie [`HTTPHeaders` reference](https://api.vapor.codes/vapor/documentation/vapor/response/headers) voor meer details.

U kunt dan `HTML` gebruiken als response type in uw routes:

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
