# Aktualizacja do wersji 4.0

Ten przewodnik pokazuje, jak zaktualizować istniejący projekt Vapor 3.x do wersji 4.x. Ten przewodnik stara się obejmować wszystkie oficjalne pakiety Vapora, a także niektóre powszechnie używane providery. Jeśli zauważysz, że czegoś brakuje, [czat zespołu Vapora](https://discord.gg/vapor) to świetne miejsce, aby poprosić o pomoc. Issues i pull requesty są również mile widziane.

## Zależności

Aby korzystać z Vapor 4, potrzebujesz Xcode 11.4 oraz macOS 10.15 lub nowszego.

Sekcja Instalacja dokumentacji omawia instalację zależności.

## Package.swift

Pierwszym krokiem do aktualizacji do Vapor 4 jest zaktualizowanie zależności twojego pakietu. Poniżej znajduje się przykład zaktualizowanego pliku Package.swift. Możesz również sprawdzić zaktualizowany [szablonowy Package.swift](https://github.com/vapor/template/blob/main/Package.swift).

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

Wszystkie pakiety, które zostały zaktualizowane pod kątem Vapor 4, będą miały zwiększony o jeden główny numer wersji.

!!! warning
    Identyfikator wersji wstępnej `-rc` jest używany, ponieważ niektóre pakiety Vapor 4 nie zostały jeszcze oficjalnie wydane.

### Stare pakiety

Niektóre pakiety Vapor 3 zostały wycofane, na przykład:

- `vapor/auth`: Teraz zawarty w Vapor.
- `vapor/core`: Wchłonięty przez kilka modułów.
- `vapor/crypto`: Zastąpiony przez SwiftCrypto (teraz zawarty w Vapor).
- `vapor/multipart`: Teraz zawarty w Vapor.
- `vapor/url-encoded-form`: Teraz zawarty w Vapor.
- `vapor-community/vapor-ext`: Teraz zawarty w Vapor.
- `vapor-community/pagination`: Teraz część Fluent.
- `IBM-Swift/LoggerAPI`: Zastąpiony przez SwiftLog.

### Zależność Fluent

`vapor/fluent` musi być teraz dodany jako osobna zależność do listy zależności i targetów. Wszystkie pakiety specyficzne dla baz danych otrzymały sufiks `-driver`, aby jasno wskazać wymaganie na `vapor/fluent`.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### Platformy

Manifesty pakietów Vapora obecnie jawnie wspierają macOS 10.15 i nowsze. Oznacza to, że twój pakiet również musi określać wspierane platformy. 

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor może w przyszłości dodać wsparcie dla dodatkowych platform. Twój pakiet może wspierać dowolny podzbiór tych platform, o ile numer wersji jest równy lub większy niż minimalne wymagania wersji Vapora. 

### Xcode

Vapor 4 wykorzystuje natywne wsparcie SPM w Xcode 11. Oznacza to, że nie musisz już generować plików `.xcodeproj`. Otwarcie folderu projektu w Xcode automatycznie rozpozna SPM i pobierze zależności. 

Możesz otworzyć swój projekt natywnie w Xcode za pomocą `vapor xcode` lub `open Package.swift`. 

Po zaktualizowaniu Package.swift może być konieczne zamknięcie Xcode i usunięcie następujących folderów z katalogu głównego:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Gdy twoje zaktualizowane pakiety zostaną poprawnie rozwiązane, powinieneś zobaczyć błędy kompilacji — prawdopodobnie sporo. Nie martw się! Pokażemy ci, jak je naprawić.

## Run

Pierwszą rzeczą do zrobienia jest zaktualizowanie pliku `main.swift` modułu Run do nowego formatu.

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

Zawartość pliku `main.swift` zastępuje plik `app.swift` modułu App, więc możesz usunąć ten plik.

## App 

Przyjrzyjmy się, jak zaktualizować podstawową strukturę modułu App.

### configure.swift

Metoda `configure` powinna zostać zmieniona, aby przyjmować instancję `Application`. 

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

Poniżej znajduje się przykład zaktualizowanej metody configure.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Serves files from `Public/` directory
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configure migrations
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

Zmiany w składni dotyczące konfigurowania takich rzeczy jak routing, middleware, fluent i inne, zostały omówione poniżej.

### boot.swift

Zawartość `boot` może zostać umieszczona w metodzie `configure`, ponieważ przyjmuje ona teraz instancję aplikacji.

### routes.swift

Metoda `routes` powinna zostać zmieniona, aby przyjmować instancję `Application`.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

Więcej informacji o zmianach w składni routingu znajduje się poniżej.

## Serwisy

API serwisów Vapor 4 zostało uproszczone, aby ułatwić ci ich odkrywanie i używanie. Serwisy są teraz udostępniane jako metody i właściwości na `Application` i `Request`, co pozwala kompilatorowi pomóc ci w ich prawidłowym użyciu. 

Aby to lepiej zrozumieć, przyjrzyjmy się kilku przykładom.

```diff
// Change the server's default port to 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

Zamiast rejestrować `NIOServerConfig` w serwisach, konfiguracja serwera jest teraz udostępniana jako proste właściwości na Application, które można nadpisać. 

```diff
// Register cors middleware
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // Create _empty_ middleware config
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

Zamiast tworzyć i rejestrować `MiddlewareConfig` w serwisach, middleware jest teraz udostępniany jako właściwość na Application, do której można dodawać kolejne elementy.

```diff
// Make a request in a route handler.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Podobnie jak Application, Request również udostępnia serwisy jako proste właściwości i metody. Serwisy specyficzne dla żądania powinny być zawsze używane wewnątrz domknięcia trasy.

Ten nowy wzorzec serwisów zastępuje typy `Container`, `Service` i `Config` z Vapor 3. 

### Providery

Providery nie są już wymagane do konfigurowania pakietów firm trzecich. Każdy pakiet zamiast tego rozszerza Application i Request o nowe właściwości i metody służące do konfiguracji.

Przyjrzyjmy się, jak Leaf jest konfigurowany w Vapor 4.

```diff
// Use Leaf for view rendering. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Aby skonfigurować Leaf, użyj właściwości `app.leaf`.

```diff
// Disable Leaf view caching.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Środowisko

Bieżące środowisko (produkcyjne, deweloperskie itd.) można uzyskać za pomocą `app.environment`. 

### Serwisy niestandardowe

Niestandardowe serwisy zgodne z protokołem `Service` i zarejestrowane w kontenerze w Vapor 3 mogą być teraz wyrażone jako rozszerzenia Application lub Request.

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

Ten serwis może być następnie dostępny za pomocą rozszerzenia zamiast `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Providery niestandardowe

Większość niestandardowych serwisów można zaimplementować za pomocą rozszerzeń, jak pokazano w poprzedniej sekcji. Jednak niektóre zaawansowane providery mogą potrzebować podpiąć się do cyklu życia aplikacji lub używać przechowywanych właściwości.

Nowy pomocnik `Lifecycle` aplikacji może być używany do rejestrowania handlerów cyklu życia.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Aby przechowywać wartości na Application, możesz użyć nowego pomocnika `Storage`. 

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

Dostęp do `app.storage` można opakować we właściwość obliczaną z ustawianiem (settable), aby stworzyć zwięzłe API.

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

Vapor 4 teraz udostępnia bezpośrednio asynchroniczne API SwiftNIO i nie próbuje przeciążać metod takich jak `map` i `flatMap` ani aliasować typów takich jak `EventLoopFuture`. Vapor 3 dostarczał przeciążenia i aliasy dla zachowania kompatybilności wstecznej z wczesnymi wersjami beta, które zostały wydane, zanim powstał SwiftNIO. Zostały one usunięte, aby zmniejszyć zamieszanie z innymi pakietami kompatybilnymi z SwiftNIO i lepiej stosować się do zalecanych dobrych praktyk SwiftNIO. 

### Zmiany nazewnictwa asynchronicznego

Najbardziej oczywistą zmianą jest to, że alias typu `Future` dla `EventLoopFuture` został usunięty. Można to naprawić dość łatwo za pomocą wyszukiwania i zamiany.

Ponadto NIO nie wspiera etykiet `to:`, które zostały dodane w Vapor 3. Biorąc pod uwagę ulepszone wnioskowanie typów w Swift 5.2, `to:` i tak jest teraz mniej potrzebne.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Metody z prefiksem `new`, takie jak `newPromise`, zostały zmienione na `make`, aby lepiej pasować do stylu Swift.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` nie jest już dostępne, ale zamiast tego zadziałają metody NIO takie jak `mapError` i `flatMapErrorThrowing`. 

Globalna metoda `flatMap` z Vapor 3 służąca do łączenia wielu futures nie jest już dostępna. Można ją zastąpić, używając metody `and` z NIO do łączenia wielu futures razem. 

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Do something with a and b.
}
```

### ByteBuffer

Wiele metod i właściwości, które wcześniej używały `Data`, teraz używa `ByteBuffer` z NIO. Ten typ jest bardziej wydajnym i potężnym typem przechowywania bajtów. Więcej informacji o jego API znajdziesz w [dokumentacji ByteBuffer SwiftNIO](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

Aby przekonwertować `ByteBuffer` z powrotem na `Data`, użyj:

```swift
Data(buffer.readableBytesView)
```

### Rzucające map / flatMap

Najtrudniejszą zmianą jest to, że `map` i `flatMap` nie mogą już rzucać błędów. `map` ma rzucającą wersję o nazwie (nieco myląco) `flatMapThrowing`. `flatMap` natomiast nie ma rzucającego odpowiednika. Może to wymagać przebudowania części kodu asynchronicznego. 

Mapy, które _nie_ rzucają błędów, powinny nadal działać poprawnie.

```swift
// Non-throwing map.
futureA.map { a in
    return b
}
```

Mapy, które _rzucają_ błędy, muszą zostać zmienione na `flatMapThrowing`. 

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

Flat-mapy, które _nie_ rzucają błędów, powinny nadal działać poprawnie.

```swift
// Non-throwing flatMap.
futureA.flatMap { a in
    return futureB
}
```

Zamiast rzucać błąd wewnątrz flat-mapy, zwróć future z błędem. Jeśli błąd pochodzi z innej rzucającej metody, można go przechwycić w do / catch i zwrócić jako future.

```swift
// Returning a caught error as a future.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

Wywołania metod rzucających można również przekształcić w `flatMapThrowing` i łączyć za pomocą krotek.

```swift
// Refactored throwing method into flatMapThrowing with tuple-chaining.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result is the value of doSomething.
    return futureB
}
```

## Routing

Trasy są teraz rejestrowane bezpośrednio na Application. 

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

Oznacza to, że nie musisz już rejestrować routera w serwisach. Po prostu przekaż aplikację do swojej metody `routes` i zacznij dodawać trasy. Wszystkie metody dostępne na `RoutesBuilder` są dostępne na `Application`. 

### Synchroniczna zawartość

Dekodowanie zawartości żądania jest teraz synchroniczne.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

To zachowanie można nadpisać, rejestrując trasy z użyciem strategii zbierania treści `.stream`. 

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Request body is now asynchronous.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### Ścieżki oddzielone przecinkami

Ścieżki muszą teraz być oddzielone przecinkami i nie mogą zawierać `/`, dla zachowania spójności. 

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### Parametry trasy

Protokół `Parameter` został usunięty na rzecz jawnie nazwanych parametrów. Zapobiega to problemom z duplikatami parametrów oraz nieuporządkowanym pobieraniem parametrów w middleware i handlerach tras.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

Użycie parametrów tras z modelami zostało omówione w sekcji Fluent.

## Middleware

`MiddlewareConfig` został zmieniony na `MiddlewareConfiguration` i jest teraz właściwością na Application. Możesz dodawać middleware do swojej aplikacji za pomocą `app.middleware`. 

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

Middleware nie może już być rejestrowany po nazwie typu. Zainicjalizuj middleware przed jego zarejestrowaniem.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

Aby usunąć cały domyślny middleware, ustaw `app.middleware` na pustą konfigurację za pomocą:

```swift
app.middleware = .init()
```

## Fluent

API Fluenta jest teraz niezależne od bazy danych. Możesz zaimportować po prostu `Fluent`.

```diff
- import FluentMySQL
+ import Fluent
```

### Modele

Wszystkie modele teraz używają protokołu `Model` i muszą być klasami.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

Wszystkie pola są deklarowane za pomocą opakowań właściwości `@Field` lub `@OptionalField`. 

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

Identyfikator modelu musi być zdefiniowany za pomocą opakowania właściwości `@ID`.

```diff
+ @ID(key: .id)
var id: UUID?
```

Modele używające identyfikatora z niestandardowym kluczem lub typem muszą używać `@ID(custom:)`.

Wszystkie modele muszą mieć statycznie zdefiniowaną nazwę tabeli lub kolekcji.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

Wszystkie modele muszą teraz mieć pusty inicjalizator. Ponieważ wszystkie właściwości używają opakowań właściwości, może on być pusty.

```diff
final class Planet: Model {
+   init() { }
}
```

Metody `save`, `update` i `create` modelu nie zwracają już instancji modelu.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

Modele nie mogą już być używane jako komponenty ścieżki trasy. Zamiast tego użyj `find` i `req.parameters.get`.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` został zmieniony na `Model.IDValue`. 

Znaczniki czasu modelu są teraz deklarowane za pomocą opakowania właściwości `@Timestamp`.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relacje

Relacje są teraz definiowane za pomocą opakowań właściwości.

Relacje typu parent używają opakowania właściwości `@Parent` i wewnętrznie zawierają właściwość pola. Klucz przekazany do `@Parent` powinien być nazwą pola przechowującego identyfikator w bazie danych.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Relacje typu children używają opakowania właściwości `@Children` z key pathem do powiązanego `@Parent`.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Relacje typu siblings używają opakowania właściwości `@Siblings` z key pathami do modelu pivot.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Modele pivot są teraz zwykłymi modelami zgodnymi z `Model`, z dwiema relacjami `@Parent` i zero lub więcej dodatkowymi polami.

### Zapytania

Kontekst bazy danych jest teraz dostępny za pomocą `req.db` w handlerach tras.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` został zmieniony na `Database`.

Key pathy do pól są teraz poprzedzone prefiksem `$`, aby wskazać opakowanie właściwości zamiast wartości pola.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migracje

Modele nie wspierają już automatycznych migracji opartych na refleksji. Wszystkie migracje muszą być napisane ręcznie. 

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Migracje są teraz typowane w oparciu o ciągi znaków i odseparowane od modeli, wykorzystując protokół `Migration`. 

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

Metody `prepare` i `revert` nie są już statyczne.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

Tworzenie schema buildera odbywa się za pomocą metody instancyjnej na `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

Metody `create`, `update` i `delete` są teraz wywoływane na schema builderze, podobnie jak działa query builder.

Definicje pól są teraz typowane w oparciu o ciągi znaków i mają następujący wzorzec:

```swift
field(<name>, <type>, <constraints>)
```

Zobacz przykład poniżej.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

Budowanie schematu może być teraz łańcuchowane podobnie jak query builder.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Konfiguracja Fluent

`DatabasesConfig` został zastąpiony przez `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` został zastąpiony przez `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repozytoria

Ponieważ sposób działania serwisów w Vapor 4 się zmienił, oznacza to również, że zmienił się sposób tworzenia repozytoriów bazodanowych. Nadal potrzebujesz protokołu takiego jak `UserRepository`, ale zamiast sprawiać, aby `final class` był zgodny z tym protokołem, powinieneś użyć zamiast tego `struct`.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

Powinieneś również usunąć zgodność z `ServiceType`, ponieważ nie istnieje ona już w Vapor 4. 
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

Zamiast tego powinieneś stworzyć `UserRepositoryFactory`:
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
Ta fabryka jest odpowiedzialna za zwracanie `UserRepository` dla danego `Request`.

Kolejnym krokiem jest dodanie rozszerzenia do `Application`, aby określić swoją fabrykę:
```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

Aby użyć rzeczywistego repozytorium wewnątrz `Request`, dodaj to rozszerzenie do `Request`:
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

Ostatnim krokiem jest określenie fabryki wewnątrz `configure.swift`
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

Możesz teraz uzyskać dostęp do swojego repozytorium w handlerach tras za pomocą: `req.users.all()` i łatwo zastąpić fabrykę wewnątrz testów.
Jeśli chcesz użyć mockowanego repozytorium wewnątrz testów, najpierw stwórz `TestUserRepository`
```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

Możesz teraz użyć tego mockowanego repozytorium w swoich testach w następujący sposób:
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
