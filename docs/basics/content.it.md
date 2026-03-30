# Content

L'API content di Vapor ti permette di codificare e decodificare facilmente struct `Codable` da e verso messaggi HTTP. La codifica [JSON](https://tools.ietf.org/html/rfc7159) è usata per impostazione predefinita con supporto integrato per [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) e [Multipart](https://tools.ietf.org/html/rfc2388). L'API è anche configurabile, permettendoti di aggiungere, modificare o sostituire le strategie di codifica per determinati tipi di contenuto HTTP.

## Panoramica

Per capire come funziona l'API `Content` di Vapor, dovresti prima comprendere alcune nozioni di base sui messaggi HTTP. Diamo un'occhiata alla seguente richiesta di esempio.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Tramite l'header `content-type` questa richiesta indica che contiene dati codificati in JSON. Come promesso, alcuni dati JSON seguono dopo gli header nel body.

### Content Struct

Il primo passo per decodificare questo messaggio HTTP è creare un tipo `Codable` che corrisponda alla struttura attesa.

```swift
struct Greeting: Content {
    var hello: String
}
```

Conformare il tipo a `Content` aggiungerà automaticamente la conformità a `Codable` insieme a ulteriori utility per lavorare con l'API content.

Una volta che hai la struttura del contenuto, puoi decodificarla dalla richiesta in arrivo usando `req.content`.

```swift
app.post("greeting") { req in
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

Il metodo di decodifica usa il tipo di contenuto della richiesta per trovare un decoder appropriato. Se non viene trovato nessun decoder, o la richiesta non contiene l'header del tipo di contenuto, verrà lanciato un errore `415`.

Ciò significa che questa route accetta automaticamente tutti gli altri tipi di contenuto supportati, come il form url-encoded:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

Nel caso di upload di file, la tua proprietà content deve essere di tipo `Data`:

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Tipi di Media Supportati

Di seguito sono riportati i tipi di media che l'API `Content` supporta nativamente.

|Nome|Valore header|Media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Non tutti i media type supportano tutte le funzionalità di `Codable`. Per esempio, JSON non supporta frammenti di primo livello e Plaintext non supporta dati annidati.

## Query

Le Content API di Vapor supportano la gestione dei dati codificati in URL nella query string dell'URL.

### Decodifica

Per capire come funziona la decodifica di una query string URL, dai un'occhiata alla seguente richiesta di esempio.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Proprio come le API per gestire il contenuto del body dei messaggi HTTP, il primo passo per analizzare le query string URL è creare una `struct` che corrisponda alla struttura attesa.

```swift
struct Hello: Content {
    var name: String?
}
```

Nota che `name` è una `String` opzionale poiché le query string URL dovrebbero sempre essere opzionali. Se vuoi richiedere un parametro non opzionale, usa un parametro di route.

Ora che hai una struct `Content` per la query string attesa di questa route, puoi decodificarla.

```swift
app.get("hello") { req -> String in
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Questa route restituirebbe la seguente risposta con la richiesta di esempio di cui sopra:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Se la query string venisse omessa, come nella seguente richiesta, verrebbe usato il nome "Anonymous".

```http
GET /hello HTTP/1.1
content-length: 0
```

### Valore Singolo

Oltre alla decodifica in una struct `Content`, Vapor supporta anche il recupero di valori singoli dalla query string usando i subscript.

```swift
let name: String? = req.query["name"]
```

## Hook

Vapor chiamerà automaticamente `beforeEncode` e `afterDecode` su un tipo `Content`. Vengono fornite implementazioni predefinite che non fanno nulla, ma puoi usare questi metodi per eseguire logica personalizzata.

```swift
// Eseguito dopo che il Content viene decodificato. `mutating` è richiesto solo per le struct, non per le classi.
mutating func afterDecode() throws {
    // Name potrebbe non essere passato, ma se lo è, non può essere una stringa vuota.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Eseguito prima che il Content venga codificato. `mutating` è richiesto solo per le struct, non per le classi.
mutating func beforeEncode() throws {
    // Bisogna *sempre* restituire un name, e non può essere una stringa vuota.
    guard
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines),
        !name.isEmpty
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## Override dei Valori Predefiniti

Gli encoder e decoder predefiniti usati dalle Content API di Vapor possono essere configurati.

### Globale

`ContentConfiguration.global` permette di cambiare gli encoder e decoder che Vapor usa per impostazione predefinita. Questo è utile per cambiare il modo in cui l'intera applicazione analizza e serializza i dati.

```swift
// crea un nuovo encoder JSON che usa date come unix-timestamp
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// sovrascrive l'encoder globale usato per il media type `.json`
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

La modifica di `ContentConfiguration` viene solitamente eseguita in `configure.swift`.

### Una Tantum

Le chiamate ai metodi di codifica e decodifica come `req.content.decode` supportano il passaggio di coder personalizzati per usi una tantum.

```swift
// crea un nuovo decoder JSON che usa date come unix-timestamp
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// decodifica la struct Hello usando il decoder personalizzato
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Coder Personalizzati

Le applicazioni e i package di terze parti possono aggiungere supporto per media type che Vapor non supporta per impostazione predefinita creando coder personalizzati.

### Content

Vapor specifica due protocolli per i coder in grado di gestire il contenuto nei body dei messaggi HTTP: `ContentDecoder` e `ContentEncoder`.

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

La conformità a questi protocolli permette ai tuoi coder personalizzati di essere registrati in `ContentConfiguration` come specificato sopra.

### URL Query

Vapor specifica due protocolli per i coder in grado di gestire il contenuto nelle query string URL: `URLQueryDecoder` e `URLQueryEncoder`.

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

La conformità a questi protocolli permette ai tuoi coder personalizzati di essere registrati in `ContentConfiguration` per gestire le query string URL usando i metodi `use(urlEncoder:)` e `use(urlDecoder:)`.

### `ResponseEncodable` Personalizzato

Un altro approccio prevede l'implementazione di `ResponseEncodable` sui tuoi tipi. Considera questo semplice tipo wrapper `HTML`:

```swift
struct HTML {
    let value: String
}
```

La sua implementazione di `ResponseEncodable` sarebbe così:

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

Se stai usando `async`/`await` puoi usare `AsyncResponseEncodable`:

```swift
extension HTML: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return .init(status: .ok, headers: headers, body: .init(string: value))
    }
}
```

Nota che questo permette di personalizzare l'header `Content-Type`. Consulta il [riferimento `HTTPHeaders`](https://api.vapor.codes/vapor/documentation/vapor/response/headers) per maggiori dettagli.

Puoi poi usare `HTML` come tipo di risposta nelle tue route:

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
