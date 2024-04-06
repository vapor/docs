# Test

Vapor include un modulo chiamato `XCTVapor` che fornisce supporto per i test utilizzando `XCTest`. Questo supporto al testing ti permette di inviare richieste di test alla tua applicazione Vapor programmaticamente o attraverso un server HTTP.

## Inizio

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

Ciascuna funzione che inizia con `test` sarà eseguita automaticamente quando la tua app viene testata.

### Eseguire i Test

Per eseguire i test su Xcode, usa `cmd+u` con `-Package` come schema. Usa `swift test --enable-test-discovery` per testare attraverso l'interfaccia a riga di comando.

## Applicazione Testabile

Inizializza un'instanza di `Application` usando l'ambiente `.testing`. Devi chiamare `app.shutdown()` prima che questa applicazione si deinizializzi.  
Lo shutdown è necessario per aiutare a rilasciare le risorse che l'app ha reclamato. In particolare è importante rilasciare i thread che l'applicazione richiede all'avvio. Se non chiami `shutdown()` sull'app dopo ogni test, potresti vedere la tua suite di test crashare con un fallimento di precondizione quando alloca thread per una nuova instanza di `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Passa la `Application` al metodo `configure(_:)` del tuo pacchetto per applicare la tua configurazione. Qualsiasi configurazione relativa ai soli test può essere applicata successivamente.

### Invia Richiesta

Per inviare una richiesta di test alla tua applicazione, usa il metodo `test`.

```swift
try app.test(.GET, "ciao") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Ciao, mondo!")
}
```

I primi due parametri sono il metodo HTTP e l'URL da interrogare. La chiusura successiva accetta la risposta HTTP che puoi verificare usando i metodi `XCTAssert`.

Per richieste più complesse, puoi fornire una chiusura `beforeRequest` per modificare gli header o per codificare il contenuto. L'[API Content](../basics/content.md) di Vapor è disponibile sia sulla richiesta che sulla risposta di test.

```swift
try app.test(.POST, "promemoria", beforeRequest: { req in
	try req.content.encode(["titolo": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

### Metodo Testable

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
