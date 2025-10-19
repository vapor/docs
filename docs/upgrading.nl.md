# Upgraden naar 4.0

Deze handleiding laat zien hoe u een bestaand Vapor 3.x project kunt opwaarderen naar 4.x. Deze handleiding probeert alle officiële pakketten van Vapor te behandelen, evenals enkele veelgebruikte leveranciers. Als u merkt dat er iets ontbreekt, dan is [Vapor's team chat](https://discord.gg/vapor) een goede plaats om om hulp te vragen. Issues en pull requests worden ook op prijs gesteld.

## Afhankelijkheden

Om Vapor 4 te gebruiken, hebt u Xcode 11.4 en macOS 10.15 of hoger nodig.

De Install sectie van de docs gaat over het installeren van afhankelijkheden.

## Package.swift

De eerste stap bij het upgraden naar Vapor 4 is het bijwerken van de afhankelijkheden van uw pakket. Hieronder staat een voorbeeld van een bijgewerkt Package.swift bestand. U kunt ook het bijgewerkte [sjabloon Package.swift](https://github.com/vapor/template/blob/main/Package.swift) bekijken.

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
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
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

Van alle pakketten die opgewaardeerd zijn voor Vapor 4 zal het hoofdversienummer met één verhoogd worden.

!!! warning "Waarschuwing"
    De `-rc` pre-release aanduiding wordt gebruikt omdat sommige pakketten van Vapor 4 nog niet officieel zijn uitgebracht.

### Oude Pakketten

Sommige pakketten zijn misschien nog niet geüpgraded. Als u er tegenkomt, dien dan een probleem in om de auteur te laten weten. 

Sommige Vapor 3 pakketten zijn afgeschreven, zoals:

- `vapor/auth`: Nu opgenomen in Vapor.
- `vapor/core`: Opgenomen in verschillende modules. 
- `vapor/crypto`: Vervangen door SwiftCrypto.
- `vapor/multipart`: Nu opgenomen in Vapor.
- `vapor/url-encoded-form`: Nu opgenomen in Vapor.
- `vapor-community/vapor-ext`: Nu opgenomen in Vapor.
- `vapor-community/pagination`: Nu onderdeel van Fluent.
- `IBM-Swift/LoggerAPI`: Vervangen door SwiftLog.

### Fluent Afhankelijkheid

`vapor/fluent` moet nu als een aparte dependency worden toegevoegd aan uw dependencies lijst en targets. Alle database-specifieke pakketten zijn aangevuld met `-driver` om de eis voor `vapor/fluent` duidelijk te maken.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
```

### Platvormen

Vapor's package manifests ondersteunen nu expliciet macOS 10.15 en hoger. Dit betekent dat uw pakket ook platformondersteuning moet specificeren. 

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor kan in de toekomst extra ondersteunde platforms toevoegen. Uw pakket mag een subset van deze platformen ondersteunen zolang het versienummer gelijk is aan of hoger is dan de minimum versie-eisen van Vapor. 

### Xcode

Vapor 4 maakt gebruik van Xcode 11's eigen SPM ondersteuning. Dit betekent dat u niet langer `.xcodeproj` bestanden hoeft te genereren. Het openen van de map van uw project in Xcode zal automatisch SPM herkennen en de afhankelijkheden binnenhalen. 

U kunt uw project openen in Xcode met `vapor xcode` of `open Package.swift`. 

Nadat u Package.swift hebt bijgewerkt, moet u wellicht Xcode sluiten en de volgende mappen uit de hoofdmap verwijderen:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Zodra uw bijgewerkte pakketten succesvol opgelost zijn, zou u compilerfouten moeten zien--waarschijnlijk heel wat. Maak u geen zorgen! We zullen u tonen hoe ze te herstellen.

## Run

De eerste opdracht is om het bestand `main.swift` van uw Run module aan te passen aan het nieuwe formaat.

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

De inhoud van het bestand `main.swift` vervangt het bestand `app.swift` van de App module, dus u kunt dat bestand verwijderen.

## App 

Laten we eens kijken hoe we de basis App module structuur kunnen bijwerken.

### configure.swift

De `configure` methode moet veranderd worden om een instantie van `Application` te accepteren. 

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

Hieronder staat een voorbeeld van een bijgewerkte configureermethode.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Wordt aangeroepen voordat uw toepassing initialiseert.
public func configure(_ app: Application) throws {
    // Serveert bestanden uit `Public/` directory
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configureer SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Migraties configureren
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

Syntax veranderingen voor het configureren van zaken als routing, middleware, fluent, en meer staan hieronder vermeld.

### boot.swift

De inhoud van `boot` kan in de `configure` methode geplaatst worden, omdat deze nu de applicatie instantie accepteert.

### routes.swift

De `routes` methode moet veranderd worden om een instantie van `Application` te accepteren.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

Meer informatie over wijzigingen in de routingsyntaxis wordt hieronder vermeld.

## Services

Vapor 4's services APIs zijn vereenvoudigd om het makkelijker te maken voor u om services te ontdekken en te gebruiken. Services worden nu getoond als methods en properties op `Application` en `Request` waardoor de compiler u kan helpen ze te gebruiken. 

Laten we, om dit beter te begrijpen, eens naar een paar voorbeelden kijken.

```diff
// Verander de standaardpoort van de server in 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

In plaats van een `NIOServerConfig` te registreren bij services, wordt server configuratie nu getoond als eenvoudige eigenschappen op Application die kunnen worden overschreven. 

```diff
// Registreer cors middleware
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

In plaats van een `MiddlewareConfig` aan te maken en te registreren bij services, worden middleware nu blootgesteld als een eigenschap op Application waaraan toegevoegd kan worden.

```diff
// Doe een verzoek in een route handler.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Net als Applicatie, stelt Request ook diensten bloot als eenvoudige eigenschappen en methoden. Request-specifieke services moeten altijd worden gebruikt binnen een routeafsluiting.

Dit nieuwe service patroon vervangt de `Container`, `Service`, en `Config` types uit Vapor 3. 

### Providers

Providers zijn niet langer verplicht om pakketten van derden te configureren. Elk pakket breidt in plaats daarvan Applicatie en Verzoek uit met nieuwe eigenschappen en methoden voor configuratie.

Kijk eens hoe Leaf is geconfigureerd in Vapor 4.

```diff
// Gebruik Leaf voor het renderen van views. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Om Leaf te configureren, gebruik de `app.leaf` eigenschap.

```diff
// Uitschakelen van de caching van de bladweergave.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Environment

De huidige omgeving (productie, ontwikkeling, etc) kan worden opgevraagd via `app.environment`. 

### Aangepaste Services

Aangepaste diensten die voldoen aan het `Service` protocol en geregistreerd zijn bij de container in Vapor 3 kunnen nu worden uitgedrukt als uitbreidingen op ofwel Applicatie of Verzoek.

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

Deze dienst kan dan worden benaderd met de extensie in plaats van `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Aangepaste Providers

De meeste aangepaste diensten kunnen worden geïmplementeerd met behulp van extensies zoals getoond in de vorige sectie. Het kan echter nodig zijn om voor sommige geavanceerde diensten in te haken op de levenscyclus van de applicatie of gebruik te maken van opgeslagen eigenschappen.

Applicatie's nieuwe `Lifecycle` helper kan gebruikt worden om lifecycle handlers te registreren.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Om waarden op te slaan op Application, kun je de nieuwe `Storage` helper gebruiken. 

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

Toegang tot `app.storage` kan worden verpakt in een instelbare berekende eigenschap om een beknopte API te maken.

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

Vapor 4 stelt nu SwiftNIO's async APIs direct beschikbaar en probeert niet om methoden als `map` en `flatMap` te overloaden of alias types als `EventLoopFuture`. Vapor 3 voorzag in overloads en aliassen voor achterwaartse compatibiliteit met vroege beta versies die uitgebracht werden voordat SwiftNIO bestond. Deze zijn verwijderd om verwarring met andere SwiftNIO compatibele pakketten te verminderen en beter de best practice aanbevelingen van SwiftNIO te volgen. 

### Async naamgeving veranderingen

De meest voor de hand liggende verandering is dat de `Future` typealias voor `EventLoopFuture` is verwijderd. Dit kan vrij eenvoudig worden opgelost met een find and replace.

Verder ondersteunt NIO niet de `to:` labels die Vapor 3 toevoegde. Gezien Swift 5.2's verbeterde type-inferentie, is `to:` nu toch minder nodig.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Methoden die voorafgegaan worden door `new`, zoals `newPromise` zijn veranderd in `make` om beter aan te sluiten bij de Swift stijl.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` is niet langer beschikbaar, maar NIO's methodes zoals `mapError` en `flatMapErrorThrowing` zullen in plaats daarvan werken. 

Vapor 3's globale `flatMap` methode voor het combineren van meerdere futures is niet langer beschikbaar. Deze kan worden vervangen door gebruik te maken van NIO's `and` methode om veel futures samen te voegen. 

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Doe iets met a en b.
}
```

### ByteBuffer

Veel methoden en eigenschappen die voorheen `Data` gebruikten, gebruiken nu NIO's `ByteBuffer`. Dit type is een krachtiger en performanter byte opslagtype. U kunt meer lezen over de API in [SwiftNIO's ByteBuffer docs](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

Om een `ByteBuffer` terug te converteren naar `Data`, gebruik je:

```swift
Data(buffer.readableBytesView)
```

### Throwing map / flatMap

De moeilijkste verandering is dat `map` en `flatMap` niet meer kunnen gooien. `map` heeft een werpversie met de (enigszins verwarrende) naam `flatMapThrowing`. `flatMap` heeft echter geen werpende tegenhanger. Dit kan betekenen dat je wat asynchrone code moet herstructureren. 

Maps die _niet_ gooien zouden prima moeten blijven werken.

```swift
// Non-throwing map.
futureA.map { a in
    return b
}
```

Maps die _wel_ gooien moeten worden hernoemd naar `flatMapThrowing`. 

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

Flat-maps die _niet_ gooien zouden prima moeten blijven werken.

```swift
// Non-throwing flatMap.
futureA.flatMap { a in
    return futureB
}
```

In plaats van het gooien van een fout in een flat-map, retourneer een toekomstige fout. Als de fout afkomstig is van een andere werpmethode, kan de fout worden opgevangen in een do / catch en geretourneerd als een future.

```swift
// Een gevangen fout als een toekomst teruggeven.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

Het aanroepen van methodes kan ook worden omgezet in een `flatMapThrowing` en geketend worden met behulp van tuples.

```swift
// Methode voor gooien omgebouwd tot flatMapThrowing met tuple-ketting.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // resultaat is de waarde van doSomething.
    return futureB
}
```

## Routing

Routes worden nu rechtstreeks in de applicatie geregistreerd. 

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

Dit betekent dat je niet langer een router hoeft te registreren bij services. Geef gewoon de applicatie door aan je `routes` methode en begin met het toevoegen van routes. Alle methodes die beschikbaar zijn op `RoutesBuilder` zijn beschikbaar op `Application`. 

### Synchrone Content

Het decoderen van de inhoud van verzoeken verloopt nu synchroon.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

Dit gedrag kan worden opgeheven door register routes die gebruik maken van de `.stream` body collectie strategie. 

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Het verzoek is nu asynchroon.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### Comma-separated paths

Paden moeten nu gescheiden zijn door komma's en mogen geen `/` bevatten voor consistentie. 

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### Route parameters

Het `Parameter` protocol is verwijderd ten gunste van expliciet benoemde parameters. Dit voorkomt problemen met dubbele parameters en ongeordende fetching van parameters in middleware en route handlers.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

Het gebruik van routeparameters met modellen wordt vermeld in het Fluent-gedeelte.

## Middleware

`MiddlewareConfig` is hernoemd naar `MiddlewareConfiguration` en is nu een property op Application. U kunt middleware aan uw app toevoegen met `app.middleware`. 

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

Middleware kan niet langer geregistreerd worden op type-naam. Initialiseer de middleware eerst alvorens te registreren.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

Om alle standaard middleware te verwijderen, stel `app.middleware` in op een lege config met:

```swift
app.middleware = .init()
```

## Fluent

Fluent's API is nu database agnostisch. U kunt alleen `Fluent` importeren.

```diff
- import FluentMySQL
+ import Fluent
```

### Models

Alle modellen gebruiken nu het `Model` protocol en moeten klassen zijn.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

Alle velden worden gedeclareerd met `@Field` of `@OptionalField` property wrappers. 

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

Het ID van een model moet worden gedefinieerd met de `@ID` property wrapper.

```diff
+ @ID(key: .id)
var id: UUID?
```

Modellen die een identifier gebruiken met een aangepaste sleutel of type moeten `@ID(custom:)` gebruiken.

Van alle modellen moet de naam van hun tabel of verzameling statisch gedefinieerd zijn.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

Alle modellen moeten nu een lege initializer hebben. Aangezien alle eigenschappen property wrappers gebruiken, kan deze leeg zijn.

```diff
final class Planet: Model {
+   init() { }
}
```

Model's `save`, `update`, en `create` retourneren niet langer de model instantie.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

Modellen kunnen niet langer worden gebruikt als route path componenten. Gebruik in plaats daarvan `find` en `req.parameters.get`.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` is hernoemd naar `Model.IDValue`. 

Model tijdstempels worden nu aangegeven met de `@Timestamp` property wrapper.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relaties

Relaties worden nu gedefinieerd met property wrappers.

Parent relaties gebruiken de `@Parent` property wrapper en bevatten intern de field property. De sleutel die aan `@Parent` wordt doorgegeven moet de naam zijn van het veld dat de identifier in de database opslaat.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Children relaties gebruiken de `@Children` eigenschap wrapper met een sleutelpad naar de gerelateerde `@Parent`.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Siblings relaties gebruiken de `@Siblings` property wrapper met sleutelpaden naar het pivot model.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Pivots zijn nu normale modellen die voldoen aan `Model` met twee `@Parent` relaties en nul of meer extra velden.

### Query

De database context wordt nu benaderd via `req.db` in route handlers.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` is hernoemd naar `Database`.

Sleutelpaden naar velden worden nu voorafgegaan door `$` om de eigenschap wrapper te specificeren in plaats van de veldwaarde.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migraties

Modellen ondersteunen niet langer op reflectie gebaseerde automatische migraties. Alle migraties moeten handmatig worden geschreven. 

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Migraties zijn nu stringly typed en losgekoppeld van modellen en gebruiken het `Migration` protocol. 

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

De `prepare` en `revert` methodes zijn niet langer statisch.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

Het aanmaken van een schema builder gebeurt via een instance methode op `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

De `create`, `update`, en `delete` methods worden nu aangeroepen op de schema builder, vergelijkbaar met hoe query builder werkt.

Velddefinities zijn nu stringent getypeert en volgen het patroon:

```swift
field(<name>, <type>, <constraints>)
```

Zie onderstaand voorbeeld.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

Schema bouw kan nu aaneengeschakeld worden zoals query bouwer.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Fluent Configuratie

`DatabasesConfig` is vervangen door `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` is vervangen door `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repositories

Omdat de manier waarop services werken in Vapor 4 is veranderd, betekent dat ook dat de manier om database repositories te maken is veranderd. Je hebt nog steeds een protocol nodig zoals `UserRepository`, maar in plaats van een `final class` te maken die voldoet aan dat protocol, moet je in plaats daarvan een `struct` maken.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

U moet ook de conformiteit van `ServiceType` verwijderen, omdat deze niet meer bestaat in Vapor 4. 
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

In plaats daarvan moet je een `UserRepositoryFactory` maken:
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
Deze fabriek is verantwoordelijk voor het retourneren van een `UserRepository` voor een `Request`.

De volgende stap is het toevoegen van een extensie aan `Application` om uw fabriek te specificeren:
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

Om het eigenlijke repository te gebruiken in een `Request` voeg je deze extensie toe aan `Request`:
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

De laatste stap is het specificeren van de fabriek in `configure.swift`.
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

Je kunt nu je repository benaderen in je route handlers met: `req.users.all()` en eenvoudig de factory binnen tests vervangen.
Als je een mocked repository in tests wilt gebruiken, maak dan eerst een `TestUserRepository`
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

Je kunt nu deze mocked repository als volgt gebruiken in je tests:
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
