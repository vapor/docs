# Testowanie

## VaporTesting

Vapor zawiera moduł o nazwie `VaporTesting`, który dostarcza pomocnicze narzędzia testowe zbudowane na bazie `Swift Testing`. Te narzędzia testowe pozwalają na wysyłanie testowych żądań do Twojej aplikacji Vapor programistycznie lub poprzez działający serwer HTTP.

!!! note
    Dla nowszych projektów lub zespołów przyjmujących Swift concurrency, zdecydowanie zalecane jest korzystanie z `Swift Testing` zamiast `XCTest`.

### Pierwsze kroki

Aby użyć modułu `VaporTesting`, upewnij się, że został on dodany do celu testowego (test target) Twojego pakietu.

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
    Upewnij się, że korzystasz z odpowiedniego modułu testowego, ponieważ w przeciwnym razie niepowodzenia testów Vapor mogą nie zostać poprawnie zaraportowane.

Następnie dodaj `import VaporTesting` oraz `import Testing` na początku swoich plików testowych. Twórz struktury z nazwą `@Suite`, aby pisać przypadki testowe.

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

Każda funkcja oznaczona `@Test` zostanie uruchomiona automatycznie podczas testowania Twojej aplikacji.

Aby zapewnić, że Twoje testy uruchamiają się w sposób szeregowy (np. podczas testowania z bazą danych), dołącz opcję `.serialized` w deklaracji zestawu testów (test suite):

```swift
@Suite("App Tests with DB", .serialized)
```

### Testowalna aplikacja

Aby zapewnić uproszczoną i ustandaryzowaną konfigurację oraz zamknięcie testów, `VaporTesting` udostępnia funkcję pomocniczą `withApp`. Ta metoda hermetyzuje zarządzanie cyklem życia instancji `Application`, zapewniając, że aplikacja jest prawidłowo inicjalizowana, konfigurowana i zamykana dla każdego testu.

Przekaż metodę `configure(_:)` swojej aplikacji do funkcji pomocniczej `withApp`, aby upewnić się, że wszystkie Twoje trasy zostaną poprawnie zarejestrowane:

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### Wysyłanie żądania

Aby wysłać testowe żądanie do swojej aplikacji, użyj prywatnej metody `withApp`, a wewnątrz niej metody `app.testing().test()`:

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

Pierwsze dwa parametry to metoda HTTP oraz URL, do którego wysyłane jest żądanie. Domykające domknięcie (trailing closure) przyjmuje odpowiedź HTTP, którą możesz zweryfikować za pomocą makra `#expect`.

W przypadku bardziej złożonych żądań możesz dostarczyć domknięcie `beforeRequest`, aby zmodyfikować nagłówki lub zakodować zawartość. [Content API](../basics/content.md) Vapora jest dostępne zarówno w testowym żądaniu, jak i odpowiedzi.

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

#### Metoda testowania

API testowe Vapora obsługuje wysyłanie testowych żądań programistycznie oraz przez działający serwer HTTP. Możesz określić, której metody chcesz użyć, poprzez metodę `testing`.

```swift
// Use programmatic testing.
app.testing(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testing(method: .running).test(...)
```

Domyślnie używana jest opcja `inMemory`.

Opcja `running` obsługuje przekazanie konkretnego portu do użycia. Domyślnie używany jest port `8080`.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Testy integracyjne bazy danych

Skonfiguruj bazę danych specjalnie na potrzeby testów, aby mieć pewność, że Twoja produkcyjna baza danych nigdy nie zostanie użyta podczas testów. Na przykład, jeśli korzystasz z SQLite, możesz skonfigurować swoją bazę danych w funkcji `configure(_:)` w następujący sposób:

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
    Upewnij się, że uruchamiasz testy względem właściwej bazy danych, aby zapobiec przypadkowemu nadpisaniu danych, których nie chcesz utracić.

Następnie możesz ulepszyć swoje testy, korzystając z `autoMigrate()` i `autoRevert()`, aby zarządzać schematem bazy danych oraz cyklem życia danych podczas testów. W tym celu powinieneś utworzyć własną funkcję pomocniczą `withAppIncludingDB`, która obejmuje schemat bazy danych oraz cykle życia danych:

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

A następnie użyj tej funkcji pomocniczej w swoich testach:
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

Łącząc te metody, możesz zapewnić, że każdy test rozpoczyna się od świeżego i spójnego stanu bazy danych, dzięki czemu Twoje testy są bardziej wiarygodne, a prawdopodobieństwo fałszywie pozytywnych lub fałszywie negatywnych wyników spowodowanych przez pozostałe dane jest mniejsze.


## XCTVapor

Vapor zawiera moduł o nazwie `XCTVapor`, który dostarcza pomocnicze narzędzia testowe zbudowane na bazie `XCTest`. Te narzędzia testowe pozwalają na wysyłanie testowych żądań do Twojej aplikacji Vapor programistycznie lub poprzez działający serwer HTTP.

### Pierwsze kroki

Aby użyć modułu `XCTVapor`, upewnij się, że został on dodany do celu testowego (test target) Twojego pakietu.

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

Następnie dodaj `import XCTVapor` na początku swoich plików testowych. Twórz klasy rozszerzające `XCTestCase`, aby pisać przypadki testowe.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Test here.
    }
}
```

Każda funkcja rozpoczynająca się od `test` zostanie uruchomiona automatycznie podczas testowania Twojej aplikacji.

### Testowalna aplikacja

Zainicjalizuj instancję `Application`, używając środowiska `.testing`. Musisz wywołać `app.shutdown()` przed dealokacją tej aplikacji.

Zamknięcie jest konieczne, aby pomóc zwolnić zasoby, które aplikacja zarezerwowała. W szczególności ważne jest zwolnienie wątków, o które aplikacja prosi przy starcie. Jeśli nie wywołasz `shutdown()` na aplikacji po każdym teście jednostkowym, Twój zestaw testów może ulec awarii z błędem precondition failure podczas alokowania wątków dla nowej instancji `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Przekaż `Application` do metody `configure(_:)` swojego pakietu, aby zastosować swoją konfigurację. Wszelkie konfiguracje specyficzne dla testów mogą zostać zastosowane później.

#### Wysyłanie żądania

Aby wysłać testowe żądanie do swojej aplikacji, użyj metody `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

Pierwsze dwa parametry to metoda HTTP oraz URL, do którego wysyłane jest żądanie. Domykające domknięcie (trailing closure) przyjmuje odpowiedź HTTP, którą możesz zweryfikować za pomocą metod `XCTAssert`.

W przypadku bardziej złożonych żądań możesz dostarczyć domknięcie `beforeRequest`, aby zmodyfikować nagłówki lub zakodować zawartość. [Content API](../basics/content.md) Vapora jest dostępne zarówno w testowym żądaniu, jak i odpowiedzi.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Metoda testowalna

API testowe Vapora obsługuje wysyłanie testowych żądań programistycznie oraz przez działający serwer HTTP. Możesz określić, której metody chcesz użyć, korzystając z metody `testable`.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

Domyślnie używana jest opcja `inMemory`.

Opcja `running` obsługuje przekazanie konkretnego portu do użycia. Domyślnie używany jest port `8080`.

```swift
.running(port: 8123)
```
