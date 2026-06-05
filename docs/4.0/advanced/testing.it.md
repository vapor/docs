
# Testing

## VaporTesting

Vapor include un modulo chiamato `VaporTesting` che fornisce helper per i test basati su `Swift Testing`. Questi strumenti ti permettono di inviare richieste di test alla tua applicazione Vapor sia programmaticamente che tramite un server HTTP attivo.

!!! note "Nota"
    Per progetti nuovi o team che adottano la concorrenza di Swift, si consiglia vivamente di utilizzare `Swift Testing` invece di `XCTest`.

### Inizio

Per usare il modulo `VaporTesting`, assicurati che sia stato aggiunto al target dei test del tuo pacchetto.

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

!!! warning "Attenzione"
    Assicurati di usare il modulo di testing corrispondente, altrimenti i fallimenti dei test Vapor potrebbero non essere riportati correttamente.

Poi, aggiungi `import VaporTesting` e `import Testing` all'inizio dei tuoi file di test. Crea struct con un nome `@Suite` per scrivere i casi di test.

```swift
@testable import App
import VaporTesting
import Testing

@Suite("Test App")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
        // Codice di test.
    }
}
```

Ogni funzione contrassegnata con `@Test` verrà eseguita automaticamente quando l'app viene testata.

Per assicurarti che i test vengano eseguiti in modo serializzato (ad esempio, quando testi con un database), includi l'opzione `.serialized` nella dichiarazione della suite di test:

```swift
@Suite("Test App con DB", .serialized)
```

### Applicazione Testabile

Per una gestione semplificata e standardizzata del setup e teardown dei test, `VaporTesting` offre la funzione helper `withApp`. Questo metodo incapsula la gestione del ciclo di vita dell'istanza `Application`, assicurando che l'applicazione venga inizializzata, configurata e chiusa correttamente per ogni test.

Passa il metodo `configure(_:)` della tua applicazione alla funzione helper `withApp` per assicurarti che tutte le route vengano registrate correttamente:

```swift
@Test func qualcheTest() async throws {
    try await withApp(configure: configure) { app in
        // il tuo test
    }
}
```

#### Invia Richiesta

Per inviare una richiesta di test alla tua applicazione, usa il metodo privato `withApp` e all'interno usa il metodo `app.testing().test()`:

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

I primi due parametri sono il metodo HTTP e l'URL da interrogare. La chiusura successiva accetta la risposta HTTP che puoi verificare usando la macro `#expect`.

Per richieste più complesse, puoi fornire una chiusura `beforeRequest` per modificare gli header o per codificare il contenuto. L'[API Content](../basics/content.md) di Vapor è disponibile sia sulla richiesta che sulla risposta di test.

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

#### Metodo di Testing

L'API di testing di Vapor supporta l'invio di richieste di test sia programmaticamente che tramite un server HTTP attivo. Puoi specificare quale metodo utilizzare tramite il metodo `testing`.

```swift
// Usa il testing programmatico.
app.testing(method: .inMemory).test(...)

// Esegui i test tramite un server HTTP attivo.
app.testing(method: .running).test(...)
```

Di default è usata l'opzione `inMemory.`

L'opzione `running` supporta come parametro una porta specifica da utilizzare. Di default viene usata la porta `8080`.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Test di Integrazione con Database

Configura il database specificamente per i test per assicurarti che il database live non venga mai usato durante i test. Ad esempio, se usi SQLite, puoi configurare il database nella funzione `configure(_:)` come segue:

```swift
public func configure(_ app: Application) async throws {
    // Altre configurazioni...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! warning "Attenzione"
    Assicurati di eseguire i test sul database corretto, per evitare di sovrascrivere dati che non vuoi perdere.

Puoi migliorare i tuoi test usando `autoMigrate()` e `autoRevert()` per gestire lo schema e il ciclo di vita dei dati del database durante i test. Per farlo, crea una funzione helper `withAppIncludingDB` che includa la gestione dello schema e dei dati:

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

E poi usa questa funzione helper nei tuoi test:
```swift
@Test func mioTestDiIntegrazioneDB() async throws {
    try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

Combinando questi metodi, puoi assicurarti che ogni test inizi con uno stato del database fresco e coerente, rendendo i tuoi test più affidabili e riducendo la probabilità di falsi positivi o negativi causati da dati residui.


## XCTVapor

Vapor include anche un modulo chiamato `XCTVapor` che fornisce helper per i test basati su `XCTest`. Questi strumenti ti permettono di inviare richieste di test alla tua applicazione Vapor sia programmaticamente che tramite un server HTTP attivo.

### Inizio

Per usare il modulo `XCTVapor`, assicurati sia stato aggiunto ai target dei test del tuo pacchetto.

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

Dopodiché, aggiungi `import XCTVapor` in cima ai file dei tuoi test. Per scrivere dei test, crea classi che estendono `XCTestCase`.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
    	// Esegui il test qui.
    }
}
```

Ogni funzione che inizia con `test` verrà eseguita automaticamente quando la tua app viene testata.

### Application Testabile

Inizializza un'istanza di `Application` usando l'ambiente `.testing`. Devi chiamare `app.shutdown()` prima che questa applicazione venga deinizializzata.  
Lo shutdown è necessario per rilasciare le risorse reclamate dall'app, in particolare i thread richiesti all'avvio. Se non chiami `shutdown()` sull'app dopo ogni test, potresti vedere la tua suite di test crashare con un errore di precondizione quando vengono allocati thread per una nuova istanza di `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Passa l'istanza `Application` al metodo `configure(_:)` del tuo pacchetto per applicare la configurazione. Qualsiasi configurazione relativa ai soli test può essere applicata successivamente.

#### Invia Richiesta

Per inviare una richiesta di test alla tua applicazione, usa il metodo `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

I primi due parametri sono il metodo HTTP e l'URL da interrogare. La chiusura successiva accetta la risposta HTTP che puoi verificare usando i metodi `XCTAssert`.

Per richieste più complesse, puoi fornire una chiusura `beforeRequest` per modificare gli header o per codificare il contenuto. L'[API Content](../basics/content.md) di Vapor è disponibile sia sulla richiesta che sulla risposta di test.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Metodo Testable

L'API di testing di Vapor supporta l'invio di richieste di test programmaticamente e attraverso un server HTTP attivo. Puoi specificare quale metodo vorresti usare utilizzando il metodo `testable`.

```swift
// Usa il testing programmatico.
app.testable(method: .inMemory).test(...)

// Esegui i test attraverso un server HTTP attivo.
app.testable(method: .running).test(...)
```

L'opzione `inMemory` è usata di default.

L'opzione `running` supporta il passaggio di una porta specifica da utilizzare. Di default è usata la `8080`.

```swift
.running(port: 8123)
```
