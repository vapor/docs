# Middleware

Middleware is een logische keten tussen de client en een Vapor route handler. Het staat je toe om operaties uit te voeren op inkomende verzoeken voordat ze bij de route handler komen en op uitgaande antwoorden voordat ze naar de client gaan.

## Configuratie

Middleware kan globaal worden geregistreerd (op elke route) in `configure(_:)` met behulp van `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

U kunt ook middleware toevoegen aan individuele routes door route groepen te gebruiken.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// Dit verzoek is door MyMiddleware gegaan.
}
```

### Volgorde

De volgorde waarin middleware worden toegevoegd is belangrijk. Requests die binnenkomen in uw applicatie zullen door de middleware gaan in de volgorde waarin ze zijn toegevoegd. Reacties die uw applicatie verlaten gaan in omgekeerde volgorde terug door de middleware. Route-specifieke middleware draait altijd na applicatie-middleware. Neem het volgende voorbeeld:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

Een verzoek aan `GET /hello` zal de middleware in de volgende volgorde bezoeken:

```
Request → A → B → C → Handler → C → B → A → Response
```

Middleware kan ook _geprepend_ worden, wat handig is als je een middleware wilt toevoegen _vóór_ de standaard middleware die vapor automatisch toevoegt:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Een Middleware Aanmaken

Vapor wordt geleverd met een paar nuttige middlewares, maar het kan nodig zijn dat u uw eigen maakt vanwege de vereisten van uw toepassing. U zou bijvoorbeeld een middleware kunnen maken die voorkomt dat een niet-admin gebruiker toegang heeft tot een groep routes.

> We raden aan om een `Middleware` map te maken in je `Sources/App` directory om je code georganiseerd te houden

Middleware zijn types die voldoen aan Vapor's `Middleware` of `AsyncMiddleware` protocol. Ze worden ingevoegd in de responder keten en kunnen een verzoek benaderen en manipuleren voordat het een route handler bereikt en een antwoord benaderen en manipuleren voordat het wordt geretourneerd.

Gebruikmakend van bovenstaand voorbeeld, maak een middleware om de toegang te blokkeren voor de gebruiker als hij geen admin is:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

Of als je `async`/`await` gebruikt kun je schrijven:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

Als je het antwoord wilt wijzigen, bijvoorbeeld om een aangepaste header toe te voegen, kun je ook hiervoor een middleware gebruiken. Middlewares kunnen wachten tot het antwoord van de responder keten is ontvangen en kunnen het antwoord manipuleren:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

Of als je `async`/`await` gebruikt kun je schrijven:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

`FileMiddleware` maakt het mogelijk om assets uit de Public folder van je project aan de client aan te bieden. Je zou hier statische bestanden zoals stylesheets of bitmap afbeeldingen kunnen plaatsen.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Zodra `FileMiddleware` is geregistreerd, kan een bestand als `Public/images/logo.png` worden gekoppeld vanuit een Leaf template als `<img src="/images/logo.png"/>`.

Als je server is opgenomen in een Xcode Project, zoals een iOS app, gebruik dan dit in de plaats:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Zorg er ook voor dat je Folder References gebruikt in plaats van Groups in Xcode om de mappenstructuur in resources te behouden na het bouwen van de applicatie.

## CORS Middleware

Cross-origin resource sharing (CORS) is een mechanisme waarmee beperkte bronnen op een webpagina kunnen worden opgevraagd vanuit een ander domein buiten het domein van waaruit de eerste bron werd geserveerd. REST API's die in Vapor zijn gebouwd, hebben een CORS-beleid nodig om verzoeken veilig te kunnen terugsturen naar moderne webbrowsers.

Een voorbeeldconfiguratie zou er als volgt uit kunnen zien:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors middleware moet voor standaard error middleware komen met `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Aangezien fouten gemarkeerd met `throws` onmiddelijk worden teruggestuurd naar de client, moet de `CORSMiddleware` _vóór_ de `ErrorMiddleware` worden vermeld. Anders zal de HTTP foutmelding worden teruggestuurd zonder CORS headers, en kan deze niet worden gelezen door de browser.
