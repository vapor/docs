# Client

Met Vapor's client API kunt u HTTP-oproepen doen naar externe bronnen. Het is gebouwd op [async-http-client](https://github.com/swift-server/async-http-client) en integreert met de [content](./content.md) API.

## Overzicht

Je kunt toegang krijgen tot de standaard client via `Application` of in een route handler via `Request`.

```swift
app.client // Client

app.get("test") { req in
	req.client // Client
}
```

De client van de applicatie is handig voor het maken van HTTP verzoeken tijdens configuratietijd. Als je HTTP verzoeken doet in een route handler, gebruik dan altijd de client van het verzoek.

### Methodes

Om een `GET` verzoek te doen, geef de gewenste URL door aan de `get` convenience methode.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Er zijn methoden voor elk van de HTTP methodes zoals `get`, `post`, en `delete`. Het antwoord van de client wordt teruggestuurd als een future en bevat de HTTP status, headers, en body.

### Content

Vapor's [content](./content.md) API is beschikbaar voor het verwerken van gegevens in client verzoeken en antwoorden. Om inhoud of query parameters te coderen of headers toe te voegen aan het verzoek, gebruik de `beforeSend` closure.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Encodeer de querystring naar de URL van het verzoek.
	try req.query.encode(["q": "test"])

	// Encodeer JSON naar de request body.
    try req.content.encode(["hello": "world"])
    
    // Voeg de auth header toe aan het verzoek.
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Behandel het antwoord.
```

Je kunt ook de response body decoderen met `Content` op een vergelijkbare manier:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Als je futures gebruikt, kun je `flatMapThrowing` gebruiken:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// Gebruik JSON hier
}
```

## Configuratie

U kunt de onderliggende HTTP-client configureren via de applicatie.

```swift
// Automatische doorverwijzing uitschakelen.
app.http.client.configuration.redirectConfiguration = .disallow
```

Merk op dat je de standaardclient moet configureren _voordat_ je hem voor het eerst gebruikt.
