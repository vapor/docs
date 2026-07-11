# Client

Vapor's Client-API ermöglicht es dir, HTTP-Aufrufe an externe Ressourcen zu tätigen. Sie basiert auf [async-http-client](https://github.com/swift-server/async-http-client) und ist in die [Content](content.md)-API integriert.

## Übersicht

Über `Application` oder in einem Routen-Handler über `Request` kannst du auf den Standard-Client zugreifen.

```swift
app.client // Client

app.get("test") { req in
    req.client // Client
}
```

Der Client der Application eignet sich für HTTP-Anfragen zur Konfigurationszeit. Wenn du HTTP-Anfragen in einem Routen-Handler stellst, solltest du stets den Client der Request verwenden.

### Methoden

Um eine `GET`-Anfrage zu stellen, übergibst du die gewünschte URL an die praktische Methode `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Für jede HTTP-Methode wie `get`, `post` und `delete` gibt es entsprechende Methoden. Die Antwort des Clients wird als Future zurückgegeben und enthält den HTTP-Status, die Header und den Body.

### Content

Vapor's [Content](content.md)-API steht dir zur Verfügung, um Daten in Client-Anfragen und -Antworten zu verarbeiten. Um Content, Query-Parameter zu kodieren oder Header zur Anfrage hinzuzufügen, verwendest du die Closure `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
    // Kodiere die Query-Zeichenfolge in die Anfrage-URL.
    try req.query.encode(["q": "test"])

    // Kodiere JSON in den Anfrage-Body.
    try req.content.encode(["hello": "world"])
    
    // Füge der Anfrage einen Auth-Header hinzu
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Verarbeite die Antwort.
```

Auf ähnliche Weise kannst du den Antwort-Body mit `Content` dekodieren:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Wenn du Futures verwendest, kannst du `flatMapThrowing` nutzen:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
    try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
    // Verwende JSON hier
}
```

## Konfiguration

Über die Application kannst du den zugrunde liegenden HTTP-Client konfigurieren.

```swift
// Deaktiviere das automatische Folgen von Redirects.
app.http.client.configuration.redirectConfiguration = .disallow
```

Beachte, dass du den Standard-Client konfigurieren musst, _bevor_ du ihn zum ersten Mal verwendest.

