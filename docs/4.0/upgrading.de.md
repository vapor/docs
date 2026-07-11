# Upgrade auf 4.0

Diese Anleitung zeigt dir, wie du ein bestehendes Vapor-3.x-Projekt auf 4.x aktualisierst. Diese Anleitung versucht, alle offiziellen Pakete von Vapor sowie einige häufig verwendete Provider abzudecken. Wenn dir etwas fehlt, ist [Vapors Team-Chat](https://discord.gg/vapor) ein guter Ort, um nach Hilfe zu fragen. Issues und Pull Requests sind ebenfalls willkommen.

## Abhängigkeiten

Um Vapor 4 zu verwenden, benötigst du Xcode 11.4 und macOS 10.15 oder höher.

Der Abschnitt „Installation“ der Dokumentation behandelt die Installation der Abhängigkeiten.

## Package.swift

Der erste Schritt beim Upgrade auf Vapor 4 ist die Aktualisierung der Abhängigkeiten deines Packages. Unten findest du ein Beispiel für eine aktualisierte Package.swift-Datei. Du kannst auch das aktualisierte [Template Package.swift](https://github.com/vapor/template/blob/main/Package.swift) ansehen.

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

Alle Pakete, die für Vapor 4 aktualisiert wurden, haben ihre Hauptversionsnummer um eins erhöht.

!!! warning
    Der `-rc`-Pre-Release-Bezeichner wird verwendet, da einige Pakete von Vapor 4 noch nicht offiziell veröffentlicht wurden.

### Alte Pakete

Einige Vapor-3-Pakete wurden als veraltet markiert, wie zum Beispiel:

- `vapor/auth`: Jetzt in Vapor enthalten.
- `vapor/core`: In mehrere Module aufgeteilt.
- `vapor/crypto`: Ersetzt durch SwiftCrypto (jetzt in Vapor enthalten).
- `vapor/multipart`: Jetzt in Vapor enthalten.
- `vapor/url-encoded-form`: Jetzt in Vapor enthalten.
- `vapor-community/vapor-ext`: Jetzt in Vapor enthalten.
- `vapor-community/pagination`: Jetzt Teil von Fluent.
- `IBM-Swift/LoggerAPI`: Ersetzt durch SwiftLog.

### Fluent-Abhängigkeit

`vapor/fluent` muss nun als separate Abhängigkeit zu deiner Abhängigkeitsliste und deinen Targets hinzugefügt werden. Alle datenbankspezifischen Pakete wurden mit dem Suffix `-driver` versehen, um die Abhängigkeit von `vapor/fluent` deutlich zu machen.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### Plattformen

Vapors Package-Manifeste unterstützen jetzt explizit macOS 10.15 und höher. Das bedeutet, dass dein Package ebenfalls Plattformunterstützung angeben muss.

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor könnte in Zukunft weitere unterstützte Plattformen hinzufügen. Dein Package kann jede beliebige Teilmenge dieser Plattformen unterstützen, solange die Versionsnummer gleich oder höher als Vapors Mindestversionsanforderungen ist.

### Xcode

Vapor 4 nutzt die native SPM-Unterstützung von Xcode 11. Das bedeutet, dass du keine `.xcodeproj`-Dateien mehr generieren musst. Wenn du den Ordner deines Projekts in Xcode öffnest, wird SPM automatisch erkannt und die Abhängigkeiten werden geladen.

Du kannst dein Projekt nativ in Xcode öffnen, indem du `vapor xcode` oder `open Package.swift` verwendest.

Sobald du Package.swift aktualisiert hast, musst du eventuell Xcode schließen und die folgenden Ordner aus dem Root-Verzeichnis löschen:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Sobald deine aktualisierten Pakete erfolgreich aufgelöst wurden, solltest du Compiler-Fehler sehen – wahrscheinlich sogar einige. Keine Sorge! Wir zeigen dir, wie du sie behebst.

## Run

Die erste Aufgabe ist die Aktualisierung der `main.swift`-Datei deines Run-Moduls auf das neue Format.

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

Der Inhalt der `main.swift`-Datei ersetzt die `app.swift`-Datei des App-Moduls, daher kannst du diese Datei löschen.

## App 

Schauen wir uns an, wie die grundlegende Struktur des App-Moduls aktualisiert wird.

### configure.swift

Die `configure`-Methode muss so geändert werden, dass sie eine Instanz von `Application` akzeptiert.

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

Unten ist ein Beispiel für eine aktualisierte configure-Methode.

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

Syntaxänderungen für die Konfiguration von Dingen wie Routing, Middleware, Fluent und mehr werden unten erwähnt.

### boot.swift

Der Inhalt von `boot` kann in die `configure`-Methode verschoben werden, da diese nun die Application-Instanz akzeptiert.

### routes.swift

Die `routes`-Methode muss so geändert werden, dass sie eine Instanz von `Application` akzeptiert.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

Weitere Informationen zu Änderungen an der Routing-Syntax werden unten erwähnt.

## Services

Die Services-APIs von Vapor 4 wurden vereinfacht, damit du Services leichter entdecken und verwenden kannst. Services werden nun als Methoden und Properties auf `Application` und `Request` bereitgestellt, was es dem Compiler ermöglicht, dir bei deren Verwendung zu helfen.

Um das besser zu verstehen, schauen wir uns ein paar Beispiele an.

```diff
// Change the server's default port to 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

Anstatt eine `NIOServerConfig` bei den Services zu registrieren, wird die Serverkonfiguration nun als einfache Property auf Application bereitgestellt, die überschrieben werden kann.

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

Anstatt eine `MiddlewareConfig` zu erstellen und bei den Services zu registrieren, wird Middleware nun als Property auf Application bereitgestellt, der weitere Middleware hinzugefügt werden kann.

```diff
// Make a request in a route handler.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Wie Application stellt auch Request Services als einfache Properties und Methoden bereit. Request-spezifische Services sollten immer innerhalb einer Route-Closure verwendet werden.

Dieses neue Service-Muster ersetzt die Typen `Container`, `Service` und `Config` aus Vapor 3.

### Provider

Provider werden nicht mehr benötigt, um Drittanbieter-Pakete zu konfigurieren. Stattdessen erweitert jedes Paket Application und Request um neue Properties und Methoden zur Konfiguration.

Schau dir an, wie Leaf in Vapor 4 konfiguriert wird.

```diff
// Use Leaf for view rendering. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Um Leaf zu konfigurieren, verwende die Property `app.leaf`.

```diff
// Disable Leaf view caching.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Environment

Die aktuelle Umgebung (production, development, etc.) kann über `app.environment` abgerufen werden.

### Eigene Services

Eigene Services, die in Vapor 3 dem `Service`-Protokoll entsprachen und beim Container registriert wurden, können jetzt als Extensions von entweder Application oder Request ausgedrückt werden.

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

Auf diesen Service kann dann über die Extension zugegriffen werden, anstatt über `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Eigene Provider

Die meisten eigenen Services können mithilfe von Extensions umgesetzt werden, wie im vorherigen Abschnitt gezeigt. Einige fortgeschrittene Provider müssen jedoch möglicherweise in den Lebenszyklus der Anwendung eingreifen oder gespeicherte Properties verwenden.

Der neue `Lifecycle`-Helper von Application kann verwendet werden, um Lifecycle-Handler zu registrieren.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Um Werte auf Application zu speichern, kannst du den neuen `Storage`-Helper verwenden.

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

Der Zugriff auf `app.storage` kann in eine settable computed Property eingebettet werden, um eine übersichtliche API zu schaffen.

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

Vapor 4 stellt nun die Async-APIs von SwiftNIO direkt bereit und versucht nicht mehr, Methoden wie `map` und `flatMap` zu überladen oder Typen wie `EventLoopFuture` mit Aliassen zu versehen. Vapor 3 stellte Überladungen und Aliasse für die Abwärtskompatibilität mit frühen Beta-Versionen bereit, die veröffentlicht wurden, bevor SwiftNIO existierte. Diese wurden entfernt, um Verwirrung mit anderen SwiftNIO-kompatiblen Paketen zu reduzieren und um den Best-Practice-Empfehlungen von SwiftNIO besser zu folgen.

### Änderungen an der Async-Benennung

Die offensichtlichste Änderung ist, dass der `Future`-Typealias für `EventLoopFuture` entfernt wurde. Dies lässt sich recht einfach mit Suchen und Ersetzen beheben.

Außerdem unterstützt NIO die `to:`-Labels nicht, die Vapor 3 hinzugefügt hat. Angesichts der verbesserten Typinferenz von Swift 5.2 ist `to:` ohnehin weniger notwendig.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Methoden mit dem Präfix `new`, wie `newPromise`, wurden zu `make` geändert, um besser zum Swift-Stil zu passen.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` ist nicht mehr verfügbar, aber die Methoden von NIO wie `mapError` und `flatMapErrorThrowing` funktionieren stattdessen.

Vapor 3s globale `flatMap`-Methode zum Kombinieren mehrerer Futures ist nicht mehr verfügbar. Sie kann durch die Verwendung von NIOs `and`-Methode ersetzt werden, um mehrere Futures miteinander zu kombinieren.

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Do something with a and b.
}
```

### ByteBuffer

Viele Methoden und Properties, die zuvor `Data` verwendet haben, verwenden nun NIOs `ByteBuffer`. Dieser Typ ist ein leistungsfähigerer und performanterer Byte-Speichertyp. Mehr über dessen API erfährst du in [SwiftNIOs ByteBuffer-Dokumentation](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

Um einen `ByteBuffer` zurück in `Data` umzuwandeln, verwende:

```swift
Data(buffer.readableBytesView)
```

### Werfende map / flatMap

Die schwierigste Änderung ist, dass `map` und `flatMap` keine Fehler mehr werfen können. `map` hat eine werfende Variante namens (etwas verwirrend) `flatMapThrowing`. `flatMap` hat jedoch kein werfendes Gegenstück. Dies erfordert möglicherweise, dass du asynchronen Code umstrukturierst.

Maps, die _nicht_ werfen, sollten weiterhin problemlos funktionieren.

```swift
// Non-throwing map.
futureA.map { a in
    return b
}
```

Maps, die _tatsächlich_ werfen, müssen in `flatMapThrowing` umbenannt werden.

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

Flat-Maps, die _nicht_ werfen, sollten weiterhin problemlos funktionieren.

```swift
// Non-throwing flatMap.
futureA.flatMap { a in
    return futureB
}
```

Anstatt einen Fehler innerhalb eines Flat-Maps zu werfen, gib ein Future mit einem Fehler zurück. Wenn der Fehler von einer anderen werfenden Methode stammt, kann der Fehler in einem do/catch abgefangen und als Future zurückgegeben werden.

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

Werfende Methodenaufrufe können auch in ein `flatMapThrowing` umgewandelt und mithilfe von Tupeln verkettet werden.

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

Routen werden jetzt direkt bei Application registriert.

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

Das bedeutet, dass du keinen Router mehr bei den Services registrieren musst. Übergib einfach die Application an deine `routes`-Methode und beginne damit, Routen hinzuzufügen. Alle Methoden, die auf `RoutesBuilder` verfügbar sind, sind auch auf `Application` verfügbar.

### Synchroner Content

Das Dekodieren von Request-Content ist jetzt synchron.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

Dieses Verhalten kann überschrieben werden, indem Routen mit der `.stream`-Strategie zur Body-Sammlung registriert werden.

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Request body is now asynchronous.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### Kommagetrennte Pfade

Pfade müssen jetzt aus Konsistenzgründen kommagetrennt sein und dürfen kein `/` enthalten.

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### Routenparameter

Das `Parameter`-Protokoll wurde zugunsten explizit benannter Parameter entfernt. Dies verhindert Probleme mit doppelten Parametern und ungeordnetem Abrufen von Parametern in Middleware und Route-Handlern.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

Die Verwendung von Routenparametern mit Modellen wird im Fluent-Abschnitt erwähnt.

## Middleware

`MiddlewareConfig` wurde in `MiddlewareConfiguration` umbenannt und ist jetzt eine Property auf Application. Du kannst deiner App Middleware mit `app.middleware` hinzufügen.

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

Middleware kann nicht mehr anhand des Typnamens registriert werden. Initialisiere die Middleware zuerst, bevor du sie registrierst.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

Um alle Standard-Middleware zu entfernen, setze `app.middleware` mit folgendem Befehl auf eine leere Konfiguration:

```swift
app.middleware = .init()
```

## Fluent

Die API von Fluent ist jetzt datenbankunabhängig. Du kannst einfach `Fluent` importieren.

```diff
- import FluentMySQL
+ import Fluent
```

### Modelle

Alle Modelle verwenden jetzt das `Model`-Protokoll und müssen Klassen sein.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

Alle Felder werden mit den Property-Wrappern `@Field` oder `@OptionalField` deklariert.

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

Die ID eines Modells muss mit dem `@ID`-Property-Wrapper definiert werden.

```diff
+ @ID(key: .id)
var id: UUID?
```

Modelle, die einen Identifier mit eigenem Schlüssel oder Typ verwenden, müssen `@ID(custom:)` verwenden.

Alle Modelle müssen ihren Tabellen- oder Collection-Namen statisch definieren.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

Alle Modelle müssen jetzt einen leeren Initializer haben. Da alle Properties Property-Wrapper verwenden, kann dieser leer sein.

```diff
final class Planet: Model {
+   init() { }
}
```

Die Methoden `save`, `update` und `create` von Modellen geben die Modellinstanz nicht mehr zurück.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

Modelle können nicht mehr als Routen-Pfadkomponenten verwendet werden. Verwende stattdessen `find` und `req.parameters.get`.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` wurde in `Model.IDValue` umbenannt.

Zeitstempel von Modellen werden jetzt mit dem `@Timestamp`-Property-Wrapper deklariert.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relationen

Relationen werden jetzt mit Property-Wrappern definiert.

Parent-Relationen verwenden den `@Parent`-Property-Wrapper und enthalten die Field-Property intern. Der an `@Parent` übergebene Schlüssel sollte der Name des Felds sein, das den Identifier in der Datenbank speichert.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Children-Relationen verwenden den `@Children`-Property-Wrapper mit einem Key Path zur zugehörigen `@Parent`.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Siblings-Relationen verwenden den `@Siblings`-Property-Wrapper mit Key Paths zum Pivot-Modell.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Pivots sind jetzt normale Modelle, die `Model` mit zwei `@Parent`-Relationen und null oder mehr zusätzlichen Feldern entsprechen.

### Query

Auf den Datenbankkontext wird in Route-Handlern jetzt über `req.db` zugegriffen.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` wurde in `Database` umbenannt.

Key Paths zu Feldern werden jetzt mit `$` versehen, um den Property-Wrapper anstelle des Feldwerts anzugeben.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migrationen

Modelle unterstützen keine reflection-basierten automatischen Migrationen mehr. Alle Migrationen müssen manuell geschrieben werden.

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Migrationen sind jetzt stringly-typed und von den Modellen entkoppelt und verwenden das `Migration`-Protokoll.

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

Die Methoden `prepare` und `revert` sind nicht mehr statisch.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

Das Erstellen eines Schema Builders erfolgt über eine Instanzmethode auf `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

Die Methoden `create`, `update` und `delete` werden jetzt auf dem Schema Builder aufgerufen, ähnlich wie beim Query Builder.

Felddefinitionen sind jetzt stringly-typed und folgen dem Muster:

```swift
field(<name>, <type>, <constraints>)
```

Siehe das Beispiel unten.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

Der Schemaaufbau kann jetzt wie beim Query Builder verkettet werden.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Fluent-Konfiguration

`DatabasesConfig` wurde durch `app.databases` ersetzt.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` wurde durch `app.migrations` ersetzt.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repositories

Da sich die Funktionsweise von Services in Vapor 4 geändert hat, hat sich auch die Art und Weise geändert, wie man Datenbank-Repositories umsetzt. Du benötigst weiterhin ein Protokoll wie `UserRepository`, aber anstatt eine `final class` diesem Protokoll entsprechen zu lassen, solltest du stattdessen eine `struct` verwenden.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

Du solltest außerdem die Konformität zu `ServiceType` entfernen, da dieses in Vapor 4 nicht mehr existiert.
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

Stattdessen solltest du eine `UserRepositoryFactory` erstellen:
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
Diese Factory ist dafür verantwortlich, für einen `Request` ein `UserRepository` zurückzugeben.

Der nächste Schritt besteht darin, eine Extension zu `Application` hinzuzufügen, um deine Factory anzugeben:
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

Um das eigentliche Repository innerhalb eines `Request` zu verwenden, füge diese Extension zu `Request` hinzu:
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

Der letzte Schritt besteht darin, die Factory innerhalb von `configure.swift` anzugeben
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

Du kannst jetzt in deinen Route-Handlern mit `req.users.all()` auf dein Repository zugreifen und die Factory in Tests problemlos ersetzen.
Wenn du in Tests ein gemocktes Repository verwenden möchtest, erstelle zunächst ein `TestUserRepository`
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

Du kannst dieses gemockte Repository jetzt wie folgt in deinen Tests verwenden:
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
