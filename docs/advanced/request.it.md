# Request

L'oggetto [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) è passato come parametro ad ogni [route handler](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

È la finestra principale per il resto delle funzionalità di Vapor. Contiene API per il [corpo della richiesta](../basics/content.md), i [parametri della query](../basics/content.md#query), il [logger](../basics/logging.md), il [client HTTP](../basics/client.md), l'[Authenticator](../security/authentication.md) e altro ancora. Accedere a questa funzionalità tramite la richiesta mantiene la computazione sul corretto event loop e consente di simulare il comportamento per i test. È anche possibile aggiungere i propri [servizi](../advanced/services.md) alla `Request` con le estensioni.

La documentazione API completa per `Request` può essere trovata [qui](https://api.vapor.codes/vapor/documentation/vapor/request).

## Application

La proprietà `Request.application` contiene un riferimento all'oggetto [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). Questo oggetto contiene tutta la configurazione e il funzionamento principale dell'applicazione. La maggior parte di essa dovrebbe essere impostata in `configure.swift` prima che l'applicazione parta completamente, e molte delle API a basso livello non saranno necessarie nella maggior parte delle applicazioni. Una delle proprietà più utili è `Application.eventLoopGroup`, che può essere utilizzata per ottenere un `EventLoop` per i processi che ne hanno bisogno tramite il metodo `any()`. Contiene anche l'[Environment](../basics/environment.md).

## Body

Se si desidera accedere direttamente al corpo della richiesta come `ByteBuffer`, è possibile utilizzare `Request.body.data`. Esso può essere utilizzato per lo streaming dei dati dal corpo della richiesta a un file (anche se è meglio utilizzare la proprietà [`fileio`](../advanced/files.md) della richiesta) o a un altro client HTTP.

## Cookies

Anche se l'utilizzo più utile dei cookie è tramite le [sessioni](../advanced/sessions.md#configuration) integrate, è anche possibile accedere ai cookie direttamente tramite `Request.cookies`.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

Tramite `Request.headers` si può accedere ad un oggetto `HTTPHeaders`: esso contiene tutti gli header che sono state inviate inviati con la richiesta. Può, per esempio, essere utilizzato per accedere all'intestazione `Content-Type`.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Si può vedere la documentazione completa per `HTTPHeaders` [qui](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor implementa anche diverse estensioni a `HTTPHeaders` per semplificare il lavoro con gli header più comunemente utilizzati; un elenco è disponibile [qui](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties).

## Indirizzo IP

Si può accedere al `SocketAddress` che rappresenta il client tramite `Request.remoteAddress`, che può essere utile per il logging o il rate limiting utilizzando la rappresentazione stringa `Request.remoteAddress.ipAddress`. Potrebbe non rappresentare accuratamente l'indirizzo IP del client se l'applicazione è dietro un proxy inverso.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Si può vedere la documentazione completa per `SocketAddress` [qui](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
