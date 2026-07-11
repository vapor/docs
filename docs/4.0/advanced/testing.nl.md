# Testen

## VaporTesting

Vapor bevat een module genaamd `VaporTesting` die test helpers biedt, gebouwd op `Swift Testing`. Deze test helpers stellen u in staat om test verzoeken naar uw Vapor applicatie te sturen, programmatisch of draaiend over een HTTP server.

!!! note
    Voor nieuwere projecten of teams die Swift concurrency omarmen, wordt `Swift Testing` sterk aanbevolen boven `XCTest`.

### Aan De Slag

Om de `VaporTesting` module te gebruiken, zorg ervoor dat deze is toegevoegd aan het test target van uw pakket.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning
    Zorg ervoor dat u de bijbehorende test module gebruikt, want als u dit niet doet kan dit ertoe leiden dat Vapor testfouten niet correct worden gerapporteerd.

Voeg dan `import VaporTesting` en `import Testing` toe aan de top van uw test bestanden. Maak structs met een `@Suite` naam om testgevallen te schrijven.

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
        // Test here.
    }
}
```

Elke functie gemarkeerd met `@Test` zal automatisch worden uitgevoerd wanneer uw app wordt getest.

Om ervoor te zorgen dat uw tests op een geserialiseerde manier worden uitgevoerd (bijvoorbeeld bij het testen met een database), voegt u de `.serialized` optie toe aan de test suite declaratie:

```swift
@Suite("App Tests with DB", .serialized)
```

### Testbare Applicatie

Om een gestroomlijnde en gestandaardiseerde opzet en afbraak van tests te bieden, biedt `VaporTesting` de `withApp` helper functie. Deze methode kapselt het lifecycle-beheer van de `Application` instantie in en zorgt ervoor dat de applicatie voor elke test correct wordt geïnitialiseerd, geconfigureerd en afgesloten.

Geef de `configure(_:)` methode van uw applicatie door aan de `withApp` helper functie om ervoor te zorgen dat al uw routes correct worden geregistreerd:

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### Verzoek Versturen

Om een test verzoek naar je applicatie te sturen, gebruik je de `withApp` private methode en daarbinnen de `app.testing().test()` methode:

```swift
@Test("Test Hello World Route")
func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

De eerste twee parameters zijn de HTTP methode en URL om op te vragen. De afsluiter achteraan accepteert de HTTP respons die u kunt verifiëren met de `#expect` macro.

Voor meer complexe verzoeken, kunt u een `beforeRequest` closure toevoegen om headers te wijzigen of inhoud te coderen. Vapor's [Content API](../basics/content.md) is beschikbaar op zowel het test request als het antwoord.

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### Test Methode

Vapor's test API ondersteunt het versturen van test verzoeken programmatisch en via een live HTTP server. U kunt aangeven welke methode u wilt gebruiken via de `testing` methode.

```swift
// Use programmatic testing.
app.testing(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testing(method: .running).test(...)
```

De `inMemory` optie wordt standaard gebruikt.

De `running` optie ondersteunt het doorgeven van een specifieke poort om te gebruiken. Standaard wordt `8080` gebruikt.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Database Integratie Tests

Configureer de database specifiek voor testen om ervoor te zorgen dat uw live database nooit wordt gebruikt tijdens tests. Bijvoorbeeld, wanneer u SQLite gebruikt, kunt u uw database als volgt configureren in de `configure(_:)` functie:

```swift
public func configure(_ app: Application) async throws {
    // All other configurations...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! warning
    Zorg ervoor dat u uw tests uitvoert tegen de juiste database, zodat u voorkomt dat u per ongeluk gegevens overschrijft die u niet kwijt wilt raken.

Vervolgens kunt u uw tests verbeteren door `autoMigrate()` en `autoRevert()` te gebruiken om het databaseschema en de datalevenscyclus tijdens het testen te beheren. Om dit te doen, maakt u het beste uw eigen helper functie `withAppIncludingDB` die de databaseschema- en datalevenscyclus omvat:

```swift
private func withAppIncludingDB(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()   
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

En gebruik deze helper vervolgens in uw tests:
```swift
@Test func myDatabaseIntegrationTest() async throws {
    try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
} 
```

Door deze methoden te combineren, kunt u ervoor zorgen dat elke test begint met een verse en consistente databasestatus, waardoor uw tests betrouwbaarder worden en de kans op valse positieven of negatieven veroorzaakt door achtergebleven data wordt verkleind.


## XCTVapor

Vapor bevat een module genaamd `XCTVapor` die test helpers biedt, gebouwd op `XCTest`. Deze test helpers stellen u in staat om test verzoeken naar uw Vapor applicatie te sturen, programmatisch of draaiend over een HTTP server.

### Aan De Slag

Om de `XCTVapor` module te gebruiken, zorg ervoor dat deze is toegevoegd aan het test target van uw pakket.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Voeg dan `import XCTVapor` toe aan de top van uw test bestanden. Maak klassen die `XCTestCase` uitbreiden om testgevallen te schrijven.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Test here.
    }
}
```

Elke functie die begint met `test` zal automatisch worden uitgevoerd wanneer uw app wordt getest.

### Testbare Applicatie

Initialiseer een instantie van `Application` met behulp van de `.testing` omgeving. U moet `app.shutdown()` aanroepen voordat deze applicatie de-initialiseert.

De shutdown is nodig om de resources die de app heeft geclaimd vrij te geven. In het bijzonder is het belangrijk om de threads vrij te geven die de applicatie aanvraagt bij het opstarten. Als u `shutdown()` niet aanroept op de app na elke unit test, kan uw testsuite crashen met een precondition failure bij het toewijzen van threads voor een nieuwe instantie van `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Geef de `Application` door aan de `configure(_:)` methode van uw package om uw configuratie toe te passen. Eventuele test-only configuraties kunnen daarna worden toegepast.

#### Verzoek Versturen

Om een test verzoek naar je applicatie te sturen, gebruik je de `test` methode.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

De eerste twee parameters zijn de HTTP methode en URL om op te vragen. De afsluiter achteraan accepteert de HTTP respons die je kunt verifiëren met `XCTAssert` methoden.

Voor meer complexe verzoeken, kunt u een `beforeRequest` closure toevoegen om headers te wijzigen of inhoud te coderen. Vapor's [Content API](../basics/content.md) is beschikbaar op zowel het test request als het antwoord.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Testbare Methode

Vapor's test API ondersteunt het versturen van test verzoeken programmatisch en via een live HTTP server. U kunt aangeven welke methode u wilt gebruiken door gebruik te maken van de `testable` methode.

```swift
// Gebruik programmatische testen.
app.testable(method: .inMemory).test(...)

// Voer testen uit via een live HTTP server.
app.testable(method: .running).test(...)
```

De `inMemory` optie wordt standaard gebruikt.

De `running` optie ondersteunt het doorgeven van een specifieke poort om te gebruiken. Standaard wordt `8080` gebruikt.

```swift
.running(port: 8123)
```
