# Client

L'API client di Vapor ti permette di fare chiamate HTTP a risorse esterne. Si basa su [async-http-client](https://github.com/swift-server/async-http-client) e si integra con l'API [content](content.md).

## Panoramica

Puoi accedere al client di default attraverso `Application` o in un handler di route attraverso `Request`.

```swift
app.client // Client

app.get("test") { req in
	req.client // Client
}
```

Il client dell'applicazione è utile per fare richieste HTTP durante la configurazione. Se fai richieste HTTP in un handler di route, usa sempre il client della richiesta.

### Metodi

Per fare una richiesta `GET`, passa l'URL desiderato al comodo metodo `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Ci sono metodi per ogni verbo HTTP come `get`, `post`, e `delete`. La risposta del client viene ritornata come future e contiene lo stato, l'header, e il corpo HTTP.

### Contenuto

L'API [content](content.md) di Vapor è disponibile per gestire i dati nelle richieste e nelle risposte del client. Per codificare il contenuto, parametri della query o aggiungere header alla richiesta, usa la closure `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Codifica la stringa di query all'URL della richiesta.
	try req.query.encode(["q": "test"])

	// Codifica il JSON per il corpo della richiesta.
    try req.content.encode(["hello": "world"])
    
    // Aggiungi l'header di autenticazione alla richiesta
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Gestisci la risposta.
```

Puoi anche decodificare il corpo della risposta usando `Content` in modo simile:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Se usi i future puoi usare `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// Usa il JSON qui
}
```

## Configurazione

Puoi configurare il client HTTP sottostante tramite l'applicazione.

```swift
// Disabilita il redirect automatico seguente.
app.http.client.configuration.redirectConfiguration = .disallow
```

Nota che devi configurare il client di default _prima_ di usarlo per la prima volta.


