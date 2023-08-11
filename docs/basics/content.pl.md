# Content

Interfejs API treści Vapor umożliwia łatwe kodowanie / dekodowanie struktur Codable do / z wiadomości HTTP. Kodowanie [JSON](https://tools.ietf.org/html/rfc7159) jest używane domyślnie z gotową obsługą [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) i [Multipart](https://tools.ietf.org/html/rfc2388). Interfejs API jest również konfigurowalny, umożliwiając dodawanie, modyfikowanie lub zastępowanie strategii kodowania dla niektórych typów zawartości HTTP.

## Przegląd

Aby zrozumieć, jak działa content API w Vapor, należy najpierw zrozumieć kilka podstaw dotyczących komunikatów HTTP. Spójrz na poniższe przykładowe żądanie.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```
To żądanie wskazuje, że zawiera dane zakodowane w formacie JSON za pomocą nagłówka `content-type` i typu mediów `application/json`. Zgodnie z obietnicą, niektóre dane JSON następują po nagłówkach w treści.

### Struktura Content

Pierwszym krokiem do dekodowania tego komunikatu HTTP jest utworzenie typu Codable, który odpowiada oczekiwanej strukturze.

```swift
struct Greeting: Content {
    var hello: String
}
```

Zgodność typu z `Content` automatycznie doda zgodność z `Codable` wraz z dodatkowymi narzędziami do pracy z content API.
Po uzyskaniu struktury treści, można ją zdekodować z przychodzącego żądania za pomocą `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

Metoda dekodowania używa typu zawartości żądania do znalezienia odpowiedniego dekodera. Jeśli nie znaleziono dekodera lub żądanie nie zawiera nagłówka typu zawartości, zostanie zgłoszony błąd `415`.

Oznacza to, że ta trasa automatycznie akceptuje wszystkie inne obsługiwane typy zawartości, takie jak url-encoded form:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

W przypadku przesyłania plików, właściwość zawartości musi być typu `Data`

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Obsługiwane typy multimediów

Poniżej znajdują się typy multimediów domyślnie obsługiwane przez content API.

|Nazwa|Wartość nagłówka|Typ mediów|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-EncodedForm|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Nie wszystkie typy mediów obsługują wszystkie funkcje `Codable`. Na przykład JSON nie obsługuje fragmentów najwyższego poziomu, a Plaintext nie obsługuje zagnieżdżonych danych.

## Zapytanie

Interfejsy content API w Vapor obsługują dane zakodowane w adresie URL w ciągu zapytania adresu URL.

### Dekodowanie

Aby zrozumieć, jak działa dekodowanie ciągu zapytania URL, spójrz na poniższe przykładowe żądanie.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Podobnie jak w przypadku interfejsów API do obsługi treści wiadomości HTTP, pierwszym krokiem do analizowania ciągów zapytań URL jest utworzenie `struct`, który pasuje do oczekiwanej struktury.

```swift
struct Hello: Content {
    var name: String?
}
```

Zauważ, że `name` jest opcjonalnym `String`, ponieważ ciągi zapytań URL powinny być zawsze opcjonalne. Jeśli chcesz wymagać parametru, użyj zamiast tego parametru trasy.

Teraz, gdy masz już strukturę `Content` dla oczekiwanego ciągu zapytania tej trasy, możesz ją zdekodować.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Ta trasa skutkowałaby następującą odpowiedzią, biorąc pod uwagę przykładowe żądanie z góry:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Jeśli ciąg zapytania zostanie pominięty, tak jak w poniższym żądaniu, zamiast niego zostanie użyta nazwa "Anonymous".

```http
GET /hello HTTP/1.1
content-length: 0
```

### Pojedyncza wartość

Oprócz dekodowania do struktury `Content`, Vapor obsługuje również pobieranie pojedynczych wartości z ciągu zapytania przy użyciu indeksów.

```swift
let name: String? = req.query["name"]
```

## Hooks

Vapor automatycznie wywoła `beforeEncode` i `afterDecode` na typie `Content`. Dostarczane są domyślne implementacje, które nic nie robią, ale można użyć tych metod do uruchomienia niestandardowej logiki.

```swift
// Uruchamiane po zdekodowaniu tej zawartości. `mutating` jest wymagane tylko dla struktur, nie klas.
mutating func afterDecode() throws {
    // Nazwa może nie być przekazana, ale jeśli jest, to nie może być pustym ciągiem.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Nazwa nie może być pusta.")
    }
}

// Działa przed zakodowaniem tej treści. `mutating` jest wymagane tylko dla struktur, nie klas.
mutating func beforeEncode() throws {
    // Musi *zawsze* przekazywać nazwę z powrotem i nie może to być pusty ciąg znaków.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !.name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Nazwa nie może być pusta.")
    }
    self.name = name
}
```

## Zastępowanie ustawień domyślnych

Domyślne kodery i dekodery używane przez interfejsy content API w Vapor można skonfigurować.

### Globalne

`ContentConfiguration.global` pozwala zmienić kodery i dekodery używane domyślnie przez Vapor. Jest to przydatne do zmiany sposobu, w jaki cała aplikacja parsuje i serializuje dane.

```swift
// utwórz nowy koder JSON, który używa dat unix-timestamp
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// nadpisanie globalnego kodera używanego dla typu mediów `.json`
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Mutacja `ContentConfiguration` jest zwykle wykonywana w `configure.swift`. 

### Jednorazowe

Wywołania metod kodowania i dekodowania, takich jak `req.content.decode`, obsługują przekazywanie niestandardowych koderów do jednorazowych zastosowań.

```swift
// utworzenie nowego dekodera JSON, który używa dat unix-timestamp
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// dekoduje strukturę Hello przy użyciu niestandardowego dekodera
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Kodery niestandardowe

Aplikacje i pakiety innych firm mogą dodawać obsługę typów multimediów, których Vapor nie obsługuje domyślnie, tworząc niestandardowe kodery.

### Content

Vapor określa dwa protokoły dla koderów zdolnych do obsługi treści w ciałach wiadomości HTTP: `ContentDecoder` i `ContentEncoder`.

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

Zgodność z tymi protokołami umożliwia zarejestrowanie niestandardowych koderów w `ContentConfiguration`, jak określono powyżej.

### Zapytanie URL

Vapor określa dwa protokoły dla koderów zdolnych do obsługi treści w ciągach zapytań URL: `URLQueryDecoder` i `URLQueryEncoder`.

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

Zgodność z tymi protokołami pozwala na zarejestrowanie własnych koderów w `ContentConfiguration` do obsługi ciągów zapytań URL przy użyciu metod `use(urlEncoder:)` i `use(urlDecoder:)`.

### Niestandardowe `ResponseEncodable`

Inne podejście polega na implementacji `ResponseEncodable` na swoich typach. Rozważmy ten trywialny typ opakowujący `HTML`:

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

Jeśli używasz `async`/`await`, możesz użyć `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Zauważ, że pozwala to na dostosowanie nagłówka `Content-Type`. Zobacz [`HTTPHeaders` reference](https://api.vapor.codes/vapor/documentation/vapor/response/headers) po więcej szczegółów.

Następnie możesz użyć `HTML` jako typu odpowiedzi w swoich trasach:

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
