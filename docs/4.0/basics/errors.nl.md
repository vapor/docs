# Errors

Vapor bouwt voort op Swift's `Error` protocol voor foutafhandeling. Route handlers kunnen een fout `gooien` of een mislukte `EventLoopFuture` teruggeven. Het gooien of retourneren van een Swift `Error` zal resulteren in een `500` status response en de fout zal worden gelogd. `AbortError` en `DebuggableError` kunnen gebruikt worden om respectievelijk de resulterende respons en logging te veranderen. De afhandeling van fouten wordt gedaan door `ErrorMiddleware`. Deze middleware wordt standaard aan de applicatie toegevoegd en kan desgewenst worden vervangen door aangepaste logica. 

## Abort

Vapor levert een standaard error struct genaamd `Abort`. Deze struct voldoet aan zowel `AbortError` als `DebuggableError`. U kunt het initialiseren met een HTTP status en optionele faal reden.

```swift
// 404 fout, standaard "Not Found" reden gebruikt.
throw Abort(.notFound)

// 401 fout, aangepaste reden gebruikt.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

In oude asynchrone situaties waar gooien niet ondersteund wordt en je een `EventLoopFuture` moet teruggeven, zoals in een `flatMap` closure, kun je een mislukte future teruggeven.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor bevat een helper-extensie voor het unwrappen van futures met optionele waarden: `unwrap(of:)`. 

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Niet-optionele gebruiker geleverd aan closure.
}
```

Als `User.find` `nil` retourneert, zal de future mislukt zijn met de bijgeleverde fout. Anders zal de `flatMap` worden voorzien van een niet-optionele waarde. Als u `async`/`await` gebruikt, dan kunt u optionals als normaal afhandelen:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

Standaard zal elke Swift `Error` die wordt gegooid of geretourneerd door een route closure resulteren in een `500 Internal Server Error` response. Wanneer het project in debug modus is gebouwd, zal `ErrorMiddleware` een beschrijving van de fout bevatten. Dit wordt om veiligheidsredenen verwijderd wanneer het project in release mode wordt gebouwd. 

Om de resulterende HTTP response status of reden voor een bepaalde fout te configureren, conformeer het aan `AbortError`. 

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## Debuggable Error

`ErrorMiddleware` gebruikt de `Logger.report(error:)` methode voor het loggen van fouten die door uw routes worden gegooid. Deze methode controleert op conformiteit met protocollen als `CustomStringConvertible` en `LocalizedError` om leesbare berichten te loggen.

Om het loggen van fouten aan te passen, kun je je fouten conformeren aan `DebuggableError`. Dit protocol bevat een aantal nuttige eigenschappen zoals een unieke identifier, bron locatie, en stack trace. De meeste van deze eigenschappen zijn optioneel, wat het overnemen van de conformiteit eenvoudig maakt. 

Om zo goed mogelijk te voldoen aan `DebuggableError`, moet uw fout een struct zijn, zodat het bron- en stack trace informatie kan opslaan indien nodig. Hieronder is een voorbeeld van de eerder genoemde `MyError` enum bijgewerkt om een `struct` te gebruiken en bron informatie op te slaan.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` heeft verschillende andere eigenschappen zoals `possibleCauses` en `suggestedFixes` die je kunt gebruiken om de debuggability van je fouten te verbeteren. Kijk in het protocol zelf voor meer informatie.

## Stack Traces

Vapor bevat ondersteuning voor het bekijken van stack traces voor zowel normale Swift fouten als crashes. 

### Swift Backtrace

Vapor gebruikt de [SwiftBacktrace](https://github.com/swift-server/swift-backtrace) library om stack traces te leveren na een fatale fout of assertion op Linux. Om dit te laten werken, moet uw app debug symbolen bevatten tijdens het compileren.

```sh
swift build -c release -Xswiftc -g
```

### Error Traces

Standaard zal `Abort` de huidige stack trace vastleggen bij initialisatie. Uw aangepaste fout types kunnen dit bereiken door te voldoen aan `DebuggableError` en `StackTrace.capture()` op te slaan.

```swift
import Vapor

struct MyError: DebuggableError {
    var identifier: String
    var reason: String
    var stackTrace: StackTrace?

    init(
        identifier: String,
        reason: String,
        stackTrace: StackTrace? = .capture()
    ) {
        self.identifier = identifier
        self.reason = reason
        self.stackTrace = stackTrace
    }
}
```

Wanneer het [log level](logging.md#level) van uw applicatie is ingesteld op `.debug` of lager, zullen stack traces van fouten worden opgenomen in de log output. 

Stack traces worden niet opgevangen als het log level groter is dan `.debug`. Om dit gedrag op te heffen, stel `StackTrace.isCaptureEnabled` handmatig in `configure` in. 

```swift
// Leg altijd stack traces vast, ongeacht het log niveau.
StackTrace.isCaptureEnabled = true
```

## Error Middleware

`ErrorMiddleware` is de enige middleware die standaard aan je applicatie wordt toegevoegd. Deze middleware converteert Swift fouten die zijn gegooid of geretourneerd door uw route handlers naar HTTP responses. Zonder deze middleware, zullen gegooide fouten resulteren in het sluiten van de verbinding zonder een reactie. 

Om de foutafhandeling verder aan te passen dan `AbortError` en `DebuggableError` bieden, kunt u `ErrorMiddleware` vervangen door uw eigen logica voor foutafhandeling. Om dit te doen, verwijdert u eerst de standaard error middleware door `app.middleware` op een lege configuratie te zetten. Voeg vervolgens uw eigen error afhandeling middleware toe als de eerste middleware aan uw applicatie.

```swift
// Verwijder alle bestaande middleware.
app.middleware = .init()
// Voeg eerst aangepaste foutafhandeling middleware toe.
app.middleware.use(MyErrorMiddleware())
```

Zeer weinig middleware zou _vóór_ de foutafhandeling middleware moeten gaan. Een opmerkelijke uitzondering op deze regel is `CORSMiddleware`.
