# Content

A API de conteúdo do Vapor permite que você codifique / decodifique facilmente structs Codable de / para mensagens HTTP. A codificação [JSON](https://tools.ietf.org/html/rfc7159) é usada por padrão com suporte nativo para [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) e [Multipart](https://tools.ietf.org/html/rfc2388). A API também é configurável, permitindo que você adicione, modifique ou substitua estratégias de codificação para certos tipos de conteúdo HTTP.

## Visão Geral

Para entender como a API de conteúdo do Vapor funciona, você deve primeiro entender alguns conceitos básicos sobre mensagens HTTP. Veja o seguinte exemplo de requisição.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Esta requisição indica que contém dados codificados em JSON usando o header `content-type` e o media type `application/json`. Como prometido, alguns dados JSON seguem após os headers no body.

### Content Struct

O primeiro passo para decodificar esta mensagem HTTP é criar um tipo Codable que corresponda à estrutura esperada.

```swift
struct Greeting: Content {
    var hello: String
}
```

Conformar o tipo a `Content` adicionará automaticamente conformidade a `Codable` junto com utilitários adicionais para trabalhar com a API de conteúdo.

Uma vez que você tenha a estrutura de conteúdo, pode decodificá-la da requisição recebida usando `req.content`.

```swift
app.post("greeting") { req in
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

O método decode usa o tipo de conteúdo da requisição para encontrar um decoder apropriado. Se nenhum decoder for encontrado, ou a requisição não contiver o header de tipo de conteúdo, um erro `415` será lançado.

Isso significa que esta rota aceita automaticamente todos os outros tipos de conteúdo suportados, como url-encoded form:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

No caso de upload de arquivos, sua propriedade de conteúdo deve ser do tipo `Data`

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Tipos de Media Suportados

Abaixo estão os tipos de media que a API de conteúdo suporta por padrão.

|nome|valor do header|media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Nem todos os tipos de media suportam todos os recursos do `Codable`. Por exemplo, JSON não suporta fragmentos de nível superior e Plaintext não suporta dados aninhados.

## Query

As APIs de conteúdo do Vapor suportam a manipulação de dados codificados em URL na query string da URL.

### Decodificação

Para entender como funciona a decodificação de uma query string de URL, veja o seguinte exemplo de requisição.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Assim como as APIs para manipulação de conteúdo do body de mensagens HTTP, o primeiro passo para analisar query strings de URL é criar uma `struct` que corresponda à estrutura esperada.

```swift
struct Hello: Content {
    var name: String?
}
```

Note que `name` é uma `String` opcional, já que query strings de URL devem ser sempre opcionais. Se você quiser exigir um parâmetro, use um parâmetro de rota.

Agora que você tem uma struct `Content` para a query string esperada desta rota, pode decodificá-la.

```swift
app.get("hello") { req -> String in
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Esta rota resultaria na seguinte resposta dado o exemplo de requisição acima:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Se a query string fosse omitida, como na seguinte requisição, o nome "Anonymous" seria usado.

```http
GET /hello HTTP/1.1
content-length: 0
```

### Valor Único

Além de decodificar para uma struct `Content`, o Vapor também suporta buscar valores individuais da query string usando subscripts.

```swift
let name: String? = req.query["name"]
```

## Hooks

O Vapor chamará automaticamente `beforeEncode` e `afterDecode` em um tipo `Content`. Implementações padrão são fornecidas e não fazem nada, mas você pode usar esses métodos para executar lógica personalizada.

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

## Substituindo Padrões

Os encoders e decoders padrão usados pelas APIs de conteúdo do Vapor podem ser configurados.

### Global

`ContentConfiguration.global` permite que você altere os encoders e decoders que o Vapor usa por padrão. Isso é útil para mudar como toda a sua aplicação analisa e serializa dados.

```swift
// create a new JSON encoder that uses unix-timestamp dates
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// override the global encoder used for the `.json` media type
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

A mutação de `ContentConfiguration` é geralmente feita em `configure.swift`.

### Uso Pontual

Chamadas a métodos de codificação e decodificação como `req.content.decode` suportam a passagem de coders personalizados para usos pontuais.

```swift
// create a new JSON decoder that uses unix-timestamp dates
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodes Hello struct using custom decoder
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Coders Personalizados

Aplicações e pacotes de terceiros podem adicionar suporte para tipos de media que o Vapor não suporta por padrão criando coders personalizados.

### Content

O Vapor especifica dois protocolos para coders capazes de manipular conteúdo em bodies de mensagens HTTP: `ContentDecoder` e `ContentEncoder`.

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

Conformar a esses protocolos permite que seus coders personalizados sejam registrados em `ContentConfiguration` conforme especificado acima.

### URL Query

O Vapor especifica dois protocolos para coders capazes de manipular conteúdo em query strings de URL: `URLQueryDecoder` e `URLQueryEncoder`.

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

Conformar a esses protocolos permite que seus coders personalizados sejam registrados em `ContentConfiguration` para manipulação de query strings de URL usando os métodos `use(urlEncoder:)` e `use(urlDecoder:)`.

### `ResponseEncodable` Personalizado

Outra abordagem envolve implementar `ResponseEncodable` em seus tipos. Considere este tipo wrapper `HTML` trivial:

```swift
struct HTML {
  let value: String
}
```

Em seguida, sua implementação de `ResponseEncodable` ficaria assim:

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

Se você estiver usando `async`/`await`, pode usar `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Note que isso permite personalizar o header `Content-Type`. Veja a [referência de `HTTPHeaders`](https://api.vapor.codes/vapor/documentation/vapor/response/headers) para mais detalhes.

Você pode então usar `HTML` como um tipo de resposta nas suas rotas:

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
