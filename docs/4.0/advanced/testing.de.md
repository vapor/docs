# Testen

## VaporTesting

Vapor enthält ein Modul namens `VaporTesting`, das Test-Hilfsfunktionen bereitstellt, die auf `Swift Testing` aufbauen. Mit diesen Test-Hilfsfunktionen kannst du Testanfragen programmatisch oder über einen laufenden HTTP-Server an deine Vapor-Anwendung senden.

!!! note
    Für neuere Projekte oder Teams, die Swift Concurrency einführen, wird `Swift Testing` gegenüber `XCTest` dringend empfohlen.

### Erste Schritte

Um das `VaporTesting`-Modul zu verwenden, stelle sicher, dass es dem Test-Target deines Pakets hinzugefügt wurde.

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
    Achte darauf, das entsprechende Testmodul zu verwenden, da es andernfalls dazu kommen kann, dass Vapor-Testfehler nicht korrekt gemeldet werden.

Füge dann `import VaporTesting` und `import Testing` am Anfang deiner Testdateien hinzu. Erstelle Structs mit einem `@Suite`-Namen, um Testfälle zu schreiben.

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

Jede mit `@Test` markierte Funktion wird automatisch ausgeführt, wenn deine App getestet wird.

Um sicherzustellen, dass deine Tests serialisiert ausgeführt werden (z. B. beim Testen mit einer Datenbank), füge die Option `.serialized` in der Deklaration der Test-Suite hinzu:

```swift
@Suite("App Tests with DB", .serialized)
```

### Testbare Anwendung

Um einen optimierten und standardisierten Aufbau und Abbau von Tests zu ermöglichen, bietet `VaporTesting` die Hilfsfunktion `withApp` an. Diese Methode kapselt die Lebenszyklusverwaltung der `Application`-Instanz und stellt sicher, dass die Anwendung für jeden Test ordnungsgemäß initialisiert, konfiguriert und heruntergefahren wird.

Übergib die `configure(_:)`-Methode deiner Anwendung an die Hilfsfunktion `withApp`, um sicherzustellen, dass alle deine Routen korrekt registriert werden:

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### Anfrage senden

Um eine Testanfrage an deine Anwendung zu senden, verwende die private Methode `withApp` und darin die Methode `app.testing().test()`:

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

Die ersten beiden Parameter sind die HTTP-Methode und die URL der Anfrage. Der abschließende Closure erhält die HTTP-Antwort, die du mit dem `#expect`-Makro überprüfen kannst.

Für komplexere Anfragen kannst du einen `beforeRequest`-Closure angeben, um Header zu ändern oder Inhalte zu kodieren. Vapors [Content API](../basics/content.md) steht sowohl für die Testanfrage als auch für die Antwort zur Verfügung.

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

#### Testing-Methode

Vapors Testing-API unterstützt das programmatische Senden von Testanfragen sowie über einen laufenden HTTP-Server. Du kannst über die Methode `testing` festlegen, welche Methode du verwenden möchtest.

```swift
// Use programmatic testing.
app.testing(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testing(method: .running).test(...)
```

Standardmäßig wird die Option `inMemory` verwendet.

Die Option `running` unterstützt die Angabe eines bestimmten zu verwendenden Ports. Standardmäßig wird `8080` verwendet.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Datenbank-Integrationstests

Konfiguriere die Datenbank speziell für Tests, um sicherzustellen, dass deine Live-Datenbank während der Tests niemals verwendet wird. Wenn du beispielsweise SQLite verwendest, könntest du deine Datenbank in der Funktion `configure(_:)` wie folgt konfigurieren:

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
    Stelle sicher, dass du deine Tests gegen die richtige Datenbank ausführst, um zu verhindern, dass versehentlich Daten überschrieben werden, die du nicht verlieren möchtest.

Anschließend kannst du deine Tests verbessern, indem du `autoMigrate()` und `autoRevert()` verwendest, um das Datenbankschema und den Datenlebenszyklus während der Tests zu verwalten. Erstelle dazu eine eigene Hilfsfunktion `withAppIncludingDB`, die das Datenbankschema und die Datenlebenszyklen einbezieht:

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

Und verwende diese Hilfsfunktion dann in deinen Tests:
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

Durch die Kombination dieser Methoden kannst du sicherstellen, dass jeder Test mit einem frischen und konsistenten Datenbankzustand beginnt, wodurch deine Tests zuverlässiger werden und die Wahrscheinlichkeit falsch positiver oder negativer Ergebnisse durch verbleibende Daten verringert wird.


## XCTVapor

Vapor enthält ein Modul namens `XCTVapor`, das Test-Hilfsfunktionen bereitstellt, die auf `XCTest` aufbauen. Mit diesen Test-Hilfsfunktionen kannst du Testanfragen programmatisch oder über einen laufenden HTTP-Server an deine Vapor-Anwendung senden.

### Erste Schritte

Um das `XCTVapor`-Modul zu verwenden, stelle sicher, dass es dem Test-Target deines Pakets hinzugefügt wurde.

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

Füge dann `import XCTVapor` am Anfang deiner Testdateien hinzu. Erstelle Klassen, die `XCTestCase` erweitern, um Testfälle zu schreiben.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Test here.
    }
}
```

Jede Funktion, die mit `test` beginnt, wird automatisch ausgeführt, wenn deine App getestet wird.

### Testbare Anwendung

Initialisiere eine Instanz von `Application` mit der Umgebung `.testing`. Du musst `app.shutdown()` aufrufen, bevor diese Anwendung deinitialisiert wird.

Das Herunterfahren ist notwendig, um die von der App beanspruchten Ressourcen freizugeben. Insbesondere ist es wichtig, die Threads freizugeben, die die Anwendung beim Start anfordert. Wenn du `shutdown()` nicht nach jedem Unit-Test auf der App aufrufst, kann es sein, dass deine Testsuite mit einem Precondition-Fehler abstürzt, wenn Threads für eine neue Instanz von `Application` zugewiesen werden.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Übergib die `Application` an die `configure(_:)`-Methode deines Pakets, um deine Konfiguration anzuwenden. Alle nur für Tests bestimmten Konfigurationen können danach angewendet werden.

#### Anfrage senden

Um eine Testanfrage an deine Anwendung zu senden, verwende die Methode `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

Die ersten beiden Parameter sind die HTTP-Methode und die URL der Anfrage. Der abschließende Closure erhält die HTTP-Antwort, die du mit den `XCTAssert`-Methoden überprüfen kannst.

Für komplexere Anfragen kannst du einen `beforeRequest`-Closure angeben, um Header zu ändern oder Inhalte zu kodieren. Vapors [Content API](../basics/content.md) steht sowohl für die Testanfrage als auch für die Antwort zur Verfügung.

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

Vapors Testing-API unterstützt das programmatische Senden von Testanfragen sowie über einen laufenden HTTP-Server. Du kannst über die Methode `testable` festlegen, welche Methode du verwenden möchtest.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

Standardmäßig wird die Option `inMemory` verwendet.

Die Option `running` unterstützt die Angabe eines bestimmten zu verwendenden Ports. Standardmäßig wird `8080` verwendet.

```swift
.running(port: 8123)
```
