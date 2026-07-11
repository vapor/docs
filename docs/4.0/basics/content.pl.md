# Content

API Content Vapora pozwala na łatwe kodowanie / dekodowanie struktur zgodnych z `Codable` do / z wiadomości HTTP. Domyślnie używane jest kodowanie [JSON](https://tools.ietf.org/html/rfc7159), z gotowym wsparciem dla [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) oraz [Multipart](https://tools.ietf.org/html/rfc2388). API jest również konfigurowalne, co pozwala na dodawanie, modyfikowanie lub zastępowanie strategii kodowania dla określonych typów treści HTTP.

## Przegląd

Aby zrozumieć, jak działa API Content Vapora, powinieneś najpierw poznać kilka podstaw dotyczących wiadomości HTTP. Spójrz na poniższy przykład żądania.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

To żądanie wskazuje, że zawiera dane zakodowane w formacie JSON, korzystając z nagłówka `content-type` oraz typu mediów `application/json`. Zgodnie z zapowiedzią, po nagłówkach w ciele żądania znajdują się dane JSON.

### Struktura Content

Pierwszym krokiem do zdekodowania tej wiadomości HTTP jest stworzenie typu zgodnego z `Codable`, który odpowiada oczekiwanej strukturze.

```swift
struct Greeting: Content {
    var hello: String
}
```

Dostosowanie typu do protokołu `Content` automatycznie doda zgodność z `Codable`, wraz z dodatkowymi narzędziami do pracy z API Content.

Gdy masz już strukturę Content, możesz zdekodować ją z przychodzącego żądania, korzystając z `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

Metoda decode korzysta z typu treści żądania, aby znaleźć odpowiedni dekoder. Jeśli nie zostanie znaleziony żaden dekoder lub żądanie nie zawiera nagłówka typu treści, zostanie rzucony błąd `415`.

Oznacza to, że ta trasa automatycznie akceptuje wszystkie inne wspierane typy treści, takie jak formularz zakodowany url-encoded:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

W przypadku przesyłania plików, twoja właściwość content musi być typu `Data`

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Wspierane typy mediów

Poniżej znajdują się typy mediów, które API Content wspiera domyślnie.

|nazwa|wartość nagłówka|typ mediów|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Nie wszystkie typy mediów wspierają wszystkie funkcje `Codable`. Na przykład JSON nie wspiera fragmentów najwyższego poziomu, a Plaintext nie wspiera danych zagnieżdżonych.

## Query

API Content Vapora wspiera obsługę danych zakodowanych url-encoded w ciągu zapytania URL.

### Dekodowanie

Aby zrozumieć, jak działa dekodowanie ciągu zapytania URL, spójrz na poniższy przykład żądania.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Podobnie jak w przypadku API do obsługi treści ciała wiadomości HTTP, pierwszym krokiem do parsowania ciągów zapytań URL jest stworzenie `struct`, który odpowiada oczekiwanej strukturze.

```swift
struct Hello: Content {
    var name: String?
}
```

Zwróć uwagę, że `name` jest opcjonalnym `String`, ponieważ ciągi zapytań URL powinny zawsze być opcjonalne. Jeśli chcesz wymagać parametru, użyj zamiast tego parametru trasy.

Teraz, gdy masz już strukturę `Content` dla oczekiwanego ciągu zapytania tej trasy, możesz go zdekodować.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Ta trasa zwróci następującą odpowiedź dla powyższego przykładowego żądania:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Gdyby ciąg zapytania został pominięty, jak w poniższym żądaniu, zamiast tego zostałoby użyte imię "Anonymous".

```http
GET /hello HTTP/1.1
content-length: 0
```

### Pojedyncza wartość

Oprócz dekodowania do struktury `Content`, Vapor wspiera również pobieranie pojedynczych wartości z ciągu zapytania za pomocą subskryptów.

```swift
let name: String? = req.query["name"]
```

## Hooki

Vapor automatycznie wywoła `beforeEncode` i `afterDecode` na typie `Content`. Dostarczane są domyślne implementacje, które nic nie robią, ale możesz użyć tych metod do uruchomienia własnej logiki.

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

## Nadpisywanie domyślnych ustawień

Domyślne kodery i dekodery używane przez API Content Vapora mogą być konfigurowane.

### Globalnie

`ContentConfiguration.global` pozwala na zmianę koderów i dekoderów, których Vapor używa domyślnie. Jest to przydatne do zmiany sposobu, w jaki cała twoja aplikacja parsuje i serializuje dane.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Modyfikacja `ContentConfiguration` odbywa się zazwyczaj w `configure.swift`.

### Jednorazowo

Wywołania metod kodowania i dekodowania, takich jak `req.content.decode`, wspierają przekazywanie własnych koderów do jednorazowego użycia.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Własne kodery

Aplikacje i pakiety zewnętrzne mogą dodać wsparcie dla typów mediów, których Vapor nie wspiera domyślnie, poprzez stworzenie własnych koderów.

### Content

Vapor definiuje dwa protokoły dla koderów zdolnych do obsługi treści w ciałach wiadomości HTTP: `ContentDecoder` i `ContentEncoder`.

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

Dostosowanie do tych protokołów pozwala na zarejestrowanie twoich własnych koderów w `ContentConfiguration`, tak jak opisano powyżej.

### URL Query

Vapor definiuje dwa protokoły dla koderów zdolnych do obsługi treści w ciągach zapytań URL: `URLQueryDecoder` i `URLQueryEncoder`.

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

Dostosowanie do tych protokołów pozwala na zarejestrowanie twoich własnych koderów w `ContentConfiguration` do obsługi ciągów zapytań URL, korzystając z metod `use(urlEncoder:)` i `use(urlDecoder:)`.

### Własne `ResponseEncodable`

Innym podejściem jest zaimplementowanie `ResponseEncodable` na twoich typach. Rozważ ten prosty typ opakowujący `HTML`:

```swift
struct HTML {
  let value: String
}
```

Wtedy jego implementacja `ResponseEncodable` wyglądałaby następująco:

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

Jeśli korzystasz z `async`/`await`, możesz użyć `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Zwróć uwagę, że pozwala to na dostosowanie nagłówka `Content-Type`. Zobacz [dokumentację `HTTPHeaders`](https://api.vapor.codes/vapor/documentation/vapor/response/headers), aby uzyskać więcej informacji.

Możesz następnie użyć `HTML` jako typu odpowiedzi w twoich trasach:

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
