# Verzoek

Het [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) object wordt doorgegeven aan elke [route handler](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Het is het belangrijkste venster naar de rest van Vapor's functionaliteit. Het bevat API's voor de [request body](../basics/content.md), [query parameters](../basics/content.md#query), [logger](../basics/logging.md), [HTTP client](../basics/client.md), [Authenticator](../security/authentication.md), en meer. Door deze functionaliteit via het verzoek te benaderen, blijft de berekening op de juiste event loop en kan het worden gemockt voor testen. Je kunt zelfs je eigen [services](../advanced/services.md) toevoegen aan `Request` met extensions.

De volledige API-documentatie voor `Request` is [hier](https://api.vapor.codes/vapor/documentation/vapor/request) te vinden.

## Application

De eigenschap `Request.application` bevat een referentie naar de [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). Dit object bevat alle configuratie en kernfunctionaliteit voor de applicatie. Het grootste deel hiervan zou alleen ingesteld moeten worden in `configure.swift`, voordat de applicatie volledig opstart, en veel van de laag-niveau API's zijn in de meeste applicaties niet nodig. Een van de meest bruikbare eigenschappen is `Application.eventLoopGroup`, die gebruikt kan worden om een `EventLoop` te verkrijgen voor processen die een nieuwe nodig hebben via de `any()` methode. Het bevat ook de [`Environment`](../basics/environment.md).

## Body

Als je directe toegang wilt tot de request body als een `ByteBuffer`, kun je `Request.body.data` gebruiken. Dit kan gebruikt worden om data van de request body te streamen naar een bestand (hoewel je hiervoor beter de [`fileio`](../advanced/files.md) eigenschap op het verzoek kunt gebruiken) of naar een andere HTTP client.

## Cookies

Hoewel de meest bruikbare toepassing van cookies via de ingebouwde [sessies](../advanced/sessions.md#configuration) is, kun je ook rechtstreeks toegang krijgen tot cookies via `Request.cookies`.

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

Een `HTTPHeaders` object is toegankelijk via `Request.headers`. Dit bevat alle headers die met het verzoek zijn meegestuurd. Het kan bijvoorbeeld gebruikt worden om de `Content-Type` header te benaderen.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Zie de verdere documentatie voor `HTTPHeaders` [hier](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor voegt ook verschillende extensions toe aan `HTTPHeaders` om het werken met de meest gebruikte headers te vergemakkelijken; een lijst is [hier](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties) beschikbaar

## IP-adres

Het `SocketAddress` dat de client vertegenwoordigt, is toegankelijk via `Request.remoteAddress`, wat nuttig kan zijn voor logging of rate limiting met behulp van de string representatie `Request.remoteAddress.ipAddress`. Het geeft mogelijk niet nauwkeurig het IP-adres van de client weer als de applicatie zich achter een reverse proxy bevindt. 

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Zie de verdere documentatie voor `SocketAddress` [hier](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
