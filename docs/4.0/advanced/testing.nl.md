# Testen

Vapor bevat een module genaamd `XCTVapor` die test helpers biedt, gebouwd op `XCTest`. Deze test helpers stellen u in staat om test verzoeken naar uw Vapor applicatie te sturen, programmatisch of draaiend over een HTTP server.

## Aan De Slag

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
    	// Test hier.
    }
}
```

Elke functie die begint met `test` zal automatisch worden uitgevoerd wanneer uw app wordt getest.

### Tests Uitvoeren

Gebruik `cmd+u` met het `-Package` schema geselecteerd om tests in Xcode uit te voeren. Gebruik `swift test --enable-test-discovery` om te testen via de CLI.

## Testbare Applicatie

Initialiseer een instantie van `Application` met behulp van de `.testing` omgeving. Je moet `app.shutdown()` aanroepen voordat deze applicatie de-initialiseert.  
De shutdown is nodig om de resources die de app heeft geclaimd vrij te geven. In het bijzonder is het belangrijk om de threads vrij te geven die de applicatie aanvraagt bij het opstarten. Als je `shutdown()` niet aanroept op de app na elke unit test, kan je testsuite crashen met een precondition failure bij het toewijzen van threads voor een nieuwe instantie van `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Geef de `Application` door aan de `configure(_:)` methode van uw package om uw configuratie toe te passen. Eventuele test-only configuraties kunnen daarna worden toegepast.

### Verzoek Versturen

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

### Testbare Methode

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
