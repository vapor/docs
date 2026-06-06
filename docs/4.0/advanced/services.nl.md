# Services

Vapor's `Application` en `Request` zijn gebouwd om uitgebreid te worden door uw applicatie en pakketten van derden. Nieuwe functionaliteit toegevoegd aan deze types worden vaak services genoemd. 

## Read Only

Het eenvoudigste type service is read-only. Deze diensten bestaan uit berekende variabelen of methoden die worden toegevoegd aan een toepassing of verzoek. 

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

Alleen-lezen diensten kunnen afhankelijk zijn van reeds bestaande diensten, zoals `client` in dit voorbeeld. Zodra de extensie is toegevoegd, kan uw aangepaste service worden gebruikt als elke andere eigenschap op aanvraag.

```swift
req.myAPI.foos()
```

## Writable

Services die state of configuratie nodig hebben kunnen `Application` en `Request` opslag gebruiken om data op te slaan. Laten we aannemen dat je de volgende `MyConfiguration` struct wilt toevoegen aan je applicatie.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Om opslag te gebruiken, moet je een `StorageKey` declareren. 

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Dit is een lege struct met een `Value` typealias die aangeeft welk type wordt opgeslagen. Door een leeg type als sleutel te gebruiken, kun je bepalen welke code toegang heeft tot de waarde in de opslag. Als het type intern of privaat is, kan alleen jouw code de waarde in de opslag wijzigen.

Voeg tenslotte een uitbreiding toe aan `Application` voor het verkrijgen en instellen van de `MyConfiguration` struct.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

Zodra de uitbreiding is toegevoegd, kunt u `myConfiguration` gebruiken als een normale eigenschap van `Application`.

```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Lifecycle

Vapor's `Application` staat u toe om lifecycle handlers te registreren. Deze laten u inhaken op gebeurtenissen zoals opstarten en afsluiten.

```swift
// Drukt "hello" af tijdens het opstarten.
struct Hello: LifecycleHandler {
    // Wordt aangeroepen voordat de toepassing opstart.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Wordt aangeroepen nadat de applicatie is opgestart.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Wordt aangeroepen voordat de applicatie wordt afgesloten.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Voeg levenscyclus handler toe.
app.lifecycle.use(Hello())
```

## Locks

Vapor's `Application` bevat mogelijkheden om code te synchroniseren met behulp van locks. Door een `LockKey` te declareren, kun je een uniek, gedeeld slot krijgen om de toegang tot je code te synchroniseren. 

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Doe iets.
}
```

Elke oproep aan `lock(for:)` met dezelfde `LockKey` zal hetzelfde slot teruggeven. Deze methode is thread-safe.

Voor een applicatie-breed slot, kun je `app.sync` gebruiken. 

```swift
app.sync.withLock {
    // Doe iets.
}
```

## Verzoek

Services die bedoeld zijn om te worden gebruikt in route handlers moeten worden toegevoegd aan `Request`. Request services moeten de logger en de event loop van het verzoek gebruiken. Het is belangrijk dat een verzoek op dezelfde event loop blijft, anders wordt een assertion geraakt wanneer het antwoord wordt teruggestuurd naar Vapor. 

Als een service de event loop van het request moet verlaten om werk te doen, moet hij ervoor zorgen dat hij terugkeert naar de event loop voordat hij klaar is. Dit kan gedaan worden met de `hop(to:)` op `EventLoopFuture`. 

Request diensten die toegang nodig hebben tot applicatie diensten, zoals configuraties, kunnen `req.application` gebruiken. Let op de thread-safety bij het benaderen van de applicatie vanuit een route handler. Over het algemeen mogen alleen leesbewerkingen worden uitgevoerd door requests. Schrijf operaties moeten worden beschermd door locks. 
