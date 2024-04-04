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

Dopo di che, aggiungi `import XCTVapor` in cima ai file dei tuoi test. Crea classe che estendono `XCTestCase` per scrivere dei test.

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

Usa `cmd+u` con lo schema `-Package` selezionato per eseguire i test in Xcode. Usa `swift test --enable-test-discovery` per testare attraverso l'interfaccia a riga di comando.

## Testable Application

Initialize an instance of `Application` using the `.testing` environment. You must call `app.shutdown()` before this application deinitializes.  
The shutdown is necessary to help release the resources that the app has claimed. In particular it is important to release the threads the application requests at startup. If you do not call `shutdown()` on the app after each unit test, you may find your test suite crash with a precondition failure when allocating threads for a new instance of `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Pass the `Application` to your package's `configure(_:)` method to apply your configuration. Any test-only configurations can be applied after.

### Send Request

To send a test request to your application, use the `test` method.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

The first two parameters are the HTTP method and URL to request. The trailing closure accepts the HTTP response which you can verify using `XCTAssert` methods.

For more complex requests, you can supply a `beforeRequest` closure to modify headers or encode content. Vapor's [Content API](../basics/content.md) is available on both the test request and response.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
	try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

### Testable Method

Vapor's testing API supports sending test requests programmatically and via a live HTTP server. You can specify which method you would like to use by using the `testable` method.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

The `inMemory` option is used by default.

The `running` option supports passing a specific port to use. By default `8080` is used.

```swift
.running(port: 8123)
```
