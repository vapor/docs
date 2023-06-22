# Content

La API de contenido de Vapor nos permite codificar / decodificar fácilmente estructuras Codable en / desde mensajes HTTP. La codificación [JSON](https://tools.ietf.org/html/rfc7159) se usa por defecto con soporte preparado para [Formulario URL-Encoded](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) y [Multipart](https://tools.ietf.org/html/rfc2388). La API también se puede configurar, permitiéndote agregar, modificar o reemplazar estrategias de codificación para ciertos tipos de contenido HTTP.

## Presentación

Para comprender cómo funciona la API de contenido de Vapor, primero debes comprender algunos conceptos básicos sobre los mensajes HTTP. Presta atención a la siguiente solicitud de ejemplo.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Esta petición indica que contiene datos codificados en JSON utilizando la cabecera (header) `content-type` y el tipo de contenido (media type) `application/json`. A continuación, algunos datos JSON se hayan en el cuerpo (body) de la petición, después de las cabeceras.

### Estructura del Contenido

El primer paso para decodificar este mensaje HTTP es crear un tipo Codable que coincida con la estructura esperada.

```swift
struct Greeting: Content {
    var hello: String
}
```

Conformar el tipo con `Content` agregará automáticamente la conformidad con `Codable`, junto con utilidades adicionales para trabajar con la API de contenido.

Una vez que tengas la estructura del contenido, puedes decodificarlo desde la solicitud entrante usando `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

El método de decodificación `decode` utiliza el tipo de contenido de la solicitud para encontrar un decodificador apropiado. Si no se encuentra un decodificador, o la solicitud no contiene el header del tipo de contenido, se lanzará un error `415`.

Eso significa que esta ruta acepta automáticamente todos los demás tipos de contenido admitidos, como el formulario url-encoded:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

En el caso de subidas de archivos, la propiedad de contenido debe ser del tipo `Data`

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Media Types Soportados

A continuación se muestran los media types que admite la API de contenido de forma predeterminada.

|nombre|valor de header|media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

No todos los media types son compatibles con todas las funciones `Codable`. Por ejemplo, JSON no admite fragmentos de nivel top-level y Plaintext no admite datos anidados.

## Consultas (Query)

Las API de contenido de Vapor admiten el manejo de datos codificados de URL en la cadena de consulta de la URL.

### Decodificación

Para comprender cómo funciona la decodificación de una cadena de consulta de URL, echa un vistazo a la siguiente solicitud de ejemplo.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Al igual que las APIs para manejar el contenido del body del mensaje HTTP, el primer paso para analizar cadenas de consulta de URL es crear un `struct` que coincida con la estructura esperada.

```swift
struct Hello: Content {
    var name: String?
}
```

Ten en cuenta que `name` es una `String` opcional, ya que las cadenas de consulta de URL siempre deben ser opcionales. Si deseas solicitar un parámetro, utiliza un parámetro de ruta en su lugar.

Ahora que tienes un struct `Content` para la cadena de consulta esperada de esta ruta, puedes decodificarla.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Esta ruta daría como resultado la siguiente respuesta dada la solicitud de ejemplo anterior:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Si se omitiera la cadena de consulta, como en la siguiente solicitud, se usaría en su lugar el nombre "Anonymous".

```http
GET /hello HTTP/1.1
content-length: 0
```

### Valores Simples

Además de decodificar a un struct `Content`, Vapor también admite la obtención de valores únicos de la cadena de consulta mediante subíndices.

```swift
let name: String? = req.query["name"]
```

## Hooks

Vapor llamará automáticamente a `beforeEncode` y `afterDecode` en un tipo `Content`. Se proporcionan implementaciones predeterminadas que no hacen nada, pero puedes usar estos métodos para ejecutar una lógica personalizada.

```swift
// Se ejecuta después de decodificar este Content. `mutating` solo se requiere para structs, no para clases.
mutating func afterDecode() throws {
    // Es posible que no se pase name, pero si lo hace, entonces no puede ser una cadena vacía.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Se ejecuta antes de que se codifique este Content. `mutating` solo se requiere para structs, no para clases.
mutating func beforeEncode() throws {
    // *Siempre* tiene que devolver un name, y no puede ser una cadena vacía.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## Sobreescribiendo Valores Predeterminados

Los codificadores y decodificadores predeterminados utilizados por las APIs de Content de Vapor se pueden configurar.

### Global

`ContentConfiguration.global` te permite cambiar los codificadores y decodificadores que usa Vapor por defecto. Esto es útil para cambiar la forma en que toda la aplicación analiza y serializa los datos.

```swift
// crea un nuevo JSON encoder que use fechas de marca de tiempo de Unix
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// sobreescriba el codificador global utilizado para el media type `.json`
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

La mutación de `ContentConfiguration` generalmente se realiza en `configure.swift`.

### Usos Únicos (One-Off)

Las llamadas a métodos de codificación y decodificación como `req.content.decode` admiten el paso de codificadores personalizados para usos únicos.

```swift
// crea un nuevo JSON decoder que use fechas de marca de tiempo de Unix
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodifica el struct Hello usando un decodificador personalizado
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Codificadores Personalizados

Las aplicaciones y paquetes de terceros pueden agregar soporte para media types que Vapor no admite de forma predeterminada mediante la creación de codificadores personalizados.

### Content

Vapor especifica dos protocolos para codificadores capaces de manejar contenido en el body de mensajes HTTP: `ContentDecoder` y `ContentEncoder`.

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

Conformar con estos protocolos permite que sus codificadores personalizados se registren en `ContentConfiguration` como se especificó anteriormente.

### URL Query

Vapor especifica dos protocolos para codificadores capaces de manejar contenido en cadenas de consulta de URL: `URLQueryDecoder` y `URLQueryEncoder`.

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

Conformar con estos protocolos permite que sus codificadores personalizados se registren en `ContentConfiguration` para manejar cadenas de consulta de URL usando los métodos `use(urlEncoder:)` y `use(urlDecoder:)`.

### `ResponseEncodable` Personalizado

Otro enfoque consiste en implementar `ResponseEncodable` en sus tipos. Considera este tipo de wrapper `HTML` trivial:

```swift
struct HTML {
  let value: String
}
```

Luego su implementación con `ResponseEncodable` se vería así:

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

Si estás usando `async`/`await`, puedes usar `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Ten en cuenta que esto permite personalizar el header `Content-Type`. Consulta la [referencia de `HTTPHeaders`](https://api.vapor.codes/vapor/documentation/vapor/response/headers) para obtener más detalles.

Luego puede usar `HTML` como tipo de respuesta en tus rutas:

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
