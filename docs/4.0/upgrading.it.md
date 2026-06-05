# Aggiornamento a 4.0

Questa guida ti mostrerà come aggiornare un progetto Vapor 3.x a Vapor 4.x. La guida cercherà di coprire tutti i cambiamenti riguardanti i pacchetti Vapor e anche alcuni dei più comuni pacchetti di terze parti. Se noti che manca qualcosa, non esitare a chiedere aiuto nella [chat del team Vapor](https://discord.gg/vapor). Anche issues e pull requests su GitHub sono ben accette.

## Dipendenze

Per usare Vapor 4, avrai bisogno di almeno Xcode 11.4 e macOS 10.15.

La sezione Installazione della documentazione contiene le istruzioni per installare le dipendenze.

## Package.swift

Il primo passo per aggiornare a Vapor 4 è aggiornare il file delle dipendenze del pacchetto. Qui è riportato un esempio di un `Package.swift` aggiornato. Puoi anche visitare il [template Package.swift aggiornato](https://github.com/vapor/template/blob/main/Package.swift).

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

Tutti i pacchetti che sono stati aggiornati a Vapor 4 avranno la versione major incrementata di 1.

!!! warning "Attenzione"
    L'identificatore di pre-rilascio `-rc` indica che alcuni pacchetti di Vapor 4 non sono ancora stati rilasciati ufficialmente.

### Vecchi Pacchetti

Alcuni dei pacchetti di Vapor 3 sono stati deprecati:

- `vapor/auth`: Ora incluso in Vapor.
- `vapor/core`: Assorbito in diversi moduli.
- `vapor/crypto`: Ora incluso in vapor tramite SwiftCrypto
- `vapor/multipart`: Ora incluso in Vapor.
- `vapor/url-encoded-form`: Ora incluso in Vapor.
- `vapor-community/vapor-ext`: Ora incluso in Vapor.
- `vapor-community/pagination`: Ora incluso in Fluent.
- `IBM-Swift/LoggerAPI`: Sostituito da SwiftLog.

### Dipendenza Fluent

Ora `vapor/fluent` dev'essere aggiunto come una dipendenza separata. Tutti i pacchetti specifici per un database hanno ottenuto il suffisso `-driver` per rendere chiara la dipendenza di `vapor/fluent`.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### Piattaforme

Ora il manifesto del pacchetto supporta esplicitamente macOS 10.15 o successivi. Questo implica che anche i progetti dovranno specificare quali piattaforme supportano.

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor potrebbe eventualmente aggiungere il supporto per piattaforme aggiuntive in futuro. I pacchetti potrebbero supportare un qualsiasi sottoinsieme di tali piattaforme finché il numero di versione è uguale o maggiore rispetto al minimo richiesto da Vapor.

### Xcode

Vapor 4 utilizza il supporto nativo di SPM di Xcode 11. Ciò significa che non ci sarà più bisogno di generare il file `.xcodeproj`. Per aprire un progetto Vapor 4 in Xcode, basterà aprire il file `Package.swift` tramite `vapor xcode` o `open Package.swift`, Xcode poi procederà a scaricare le dipendenze.

Una volta aggiornato il Package.swift, potresti dover chiudere Xcode e rimuovere i seguenti file dalla directory del progetto:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Una volta che le nuove dipendenze sono state scaricate, noterai errori di compilazione, probabilmente un bel po'. Non ti preoccupare! Ti mostreremo come risolverli.

## Run

Prima di tutto bisogna aggiornare il file `main.swift` del modulo Run al nuovo formato:

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

Il file `main.swift` andrà a sostituire il file `app.swift`, quindi potete rimuovere quel file.

## App

Diamo un'occhiata a come aggiornare la struttura di base di App.

### configure.swift

Il metodo `configure` ora accetta un'istanza di `Application`.

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

Riportiamo un esempio di un file `configure.swift` aggiornato:

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

Cambiamenti di sintassi per cose come routing, middleware, fluent, ecc. sono menzionati nelle sezioni seguenti.

### boot.swift

Il contenuto di `boot` può essere inserito nel metodo `configure` dal momento che ora accetta un'istanza di `Application`.

### routes.swift

Il metodo `routes` ora accetta un'istanza di `Application`.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

Più avanti ci saranno altre informazioni sui cambiamenti della sintassi di routing.

## Servizi

La API dei servizi di Vapor 4 è stata semplificata in modo da rendere molto più facile l'aggiunta di nuovi servizi. Ora i servizi sono esposti come metodi e proprietà sulle istanze di `Application` e `Request`.

Per capire meglio questo concetto, diamo un'occhiata a qualche esempio:

```diff
// Cambiamento della porta di default del server a 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

Invece che registrare un un `NIOServerConfig` ai servizi, la configurazione del server è esposta come una proprietà su `Application` e può essere modificata direttamente.

```diff
// Registrazione del middleware CORS
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

Invece che registrare un `MiddlewareConfig` ai servizi, i middleware possono essere aggiunti direttamente a `Application` tramite una proprietà

```diff
// Fare una richiesta in un route handler
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Come Application, anche Request espone servizi come proprietà e metodi. È fortemente consigliato l'uso di servizi specifici alla Request da dentro le closure dei route handler.

Questo nuovo pattern va a sostituire il vecchio pattern di `Container` e `Service` e `Config` che era usato in Vapor 3.

### Provider

I provider sono stati rimossi in Vapor 4. I provider erano usati per registrare servizi e configurazioni ai servizi. Ora i pacchetti possono estendere direttamente `Application` e `Request` per registrare servizi e configurazioni.

Diamo un'occhiata a come è configurato Leaf in Vapor 4.

```diff
// Usa Leaf per renderizzare le view
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Per usare Leaf, basta usare `app.leaf`.

```diff
// Disabilita il caching delle view di Leaf
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Ambiente

Si può accedere all'ambiente attuale (produzione, sviluppo, ecc.) tramite la proprietà `app.environment`.

### Servizi Personalizzati

I servizi personalizzati che implementano il protocollo `Service` ed erano registrati al container in Vapor 3 vengono ora espressi come estensioni di Application o Request.

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

Per accedere a questo servizio non c'è più bisogno di usare `make`:

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Provider Personalizzati

La maggior parte dei servizi può essere implementata come indicato sopra, tuttavia se si deve poter accedere al `Lifecycle` dell'applicazione si può fare così:

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Per salvare dati su Application, si può utilizzare il nuovo `Application.storage`:

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

L'accesso a `Application.storage` può essere avvolto in una proprietà computata per rendere il codice più leggibile:

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

Vapor 4 utilizza le API asincrone di SwiftNIO direttamente senza fare l'overload di metodi come `map` e `flatMap` o tipi alias come `EventLoopFuture`. Vapor 3 forniva overload ed alias per retrocompatiblità con versioni di Vapor che non usavano SwiftNIO.

### Cambi di nome 

Il cambiamento più ovvio è che il typealias `Future` di `EventLoopFuture` è stato rimosso. Si può risolvere questo problema semplicemente usando "trova e sostituisci".

In più NIO non supporta il label `to:` che veniva usato da Vapor 3, che comunque dato il nuovo sistema di inferenza dei tipi di Swift 5.2 non è più necessario.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Metodi con il prefisso `new`, come `newPromise`, sono stati rinominati in `make` per essere più coerenti con lo standard di Swift.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` non è più disponibile. Si può usare `mapError` o `flatMapErrorThrowing` al suo posto.

Il `flatMap` globale di Vapor 3 per combinare diversi futuri non è più disponibile. Si può utilizzare `and` al suo posto.


```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Fai qualcosa con a e b.
}
```

### ByteBuffer

Molti metodi e proprietà che utilizzavano `Data` ora usano `ByteBuffer`, un tipo di storage di byte più potente e performante. Potete leggere di più su `ByteBuffer` nella [documentazione di SwiftNIO](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

Per convertire un `ByteBuffer` in `Data` si può usare:

```swift
Data(buffer.readableBytesView)
```

### Throwing map / flatMap

La difficoltà maggiore è che `map` e `flatMap` non possono più lanciare errori. `map` ha una versione che può lanciare errori, `flatMapThrowing`. `flatMap` non ha una versione che può lanciare errori, questo potrebbe implicare il cambiamento della struttura del vostro codice asincrono.

Map che _non_ lanciano errori dovrebbero continuare a funzionare senza problemi.

```swift
// Non lancia errori
futureA.map { a in
    return b
}
```

Map che lanciano errori devono essere aggiornate a `flatMapThrowing`:

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

FlatMap che _non_ lanciano errori dovrebbero continuare a funzionare senza problemi.

```swift
// Non lancia errori
futureA.flatMap { a in
    return futureB
}
```

Invece di lanciare errori dentro una flatMap, si può ritornare un errore futuro. Se l'errore ha origine da un altro metodo, si può utilizzare il costrutto do / catch.

```swift
// Ritorna un errore futuro:
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

Se l'errore è generato direttamente dentro la flatMap, si può usare `flatMapThrowing`:

```swift
// Metodo che lancia errori riscritto con flatMapThrowing
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result è il valore ritornato da doSomething()
    return futureB
}
```

## Routing

Ora le route sono registrate direttamente su Application.

```swift
app.get("hello") { req in
    return "Hello, world!"
}
```

Ciò significa che non c'è più bisogno di registrare un router ai servizi. Basta passare l'istanza di `Application` al metodo `routes` e si può cominciare ad aggiungere endpoint. Tutti i metodi disponibili sul `RoutesBuilder` sono disponibili su `Application`.

### Contenuto Sincrono

La decodifica delle richieste è ora sincrona.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

Si può fare l'override di questo comportamento utilizzando la strategia di collezione del body `.stream`.

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Il body della richiesta è ora asincrono.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### URL divisi da virgole

In Vapor 4 gli URL sono divisi da virgole e non devono contenere `/`.

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Gestisci la richiesta
}
```

### Parametri di una route

Il protocollo `Parameter` è stato rimosso per promuovere l'uso di parametri chiamati esplicitamente. In questo modo si evitano problemi di parametri duplicati e il fetching non ordinato dei parametri nei middleware e nei gestori delle route.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

Si tratta dell'utilizzo dei parametri nelle routes nella sezione di Fluent.

## Middleware

`MiddlewareConfig` è stato rinominato in `MiddlewareConfiguration` ed è ora una proprietà di `Application`. Si possono aggiungere dei middleware all'applicazione usando `app.middleware`.

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

Ora è obbligatorio inizializzare i Middleware prima di registrarli.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

Per rimuovere tutti i middleware di default si può utilizzare:

```swift
app.middleware = .init()
```

## Fluent

Ora l'API di Fluent è indipendente dal database su cui viene utilizzata. Basta importare `Fluent`.

```diff
- import FluentMySQL
+ import Fluent
```

### Modelli

I modelli utilizzano il protocollo `Model` e devono essere delle classi:

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

Tutti i campi sono dichiarati utilizzando `@Field` o `@OptionalField`.

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

L'ID di un modello dev'essere definito utilizzando `@ID`.

```diff
+ @ID(key: "id")
var id: UUID?
```

I modelli che utilizzano un ID personalizzato devono utilizzare `@ID(custom:)`.

Tutti i modelli devono avere il nome della loro tabella definito staticamente.

```diff
final class Planet: Model {
+     static let schema = "Planet"
```

I metodi `save`, `update` e `create` non ritornano più l'istanza del modello.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

I modelli non possono più venire utilizzati come parametri del route path. Si può utilizzare `find` e `req.parameters.get`.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` è stato rinominato in `Model.IDValue`.

I timestamp sono ora dichiarati usando `@Timestamp`.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relazioni

Le relazioni sono ora dichiarate usando `@Parent`, `@Children` e `@Siblings`.

Le relazioni `@Parent` contengono il campo internamente. La chiave passata a `@Parent` è il nome del campo che contiene la chiave esterna.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Le relazioni `@Children` hanno un key path al relativo `@Parent`.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Le relazioni `@Siblings` hanno dei key path al relativo ad una tabella pivot.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Le tabelle pivot sono modelli normali che conformano a `Model` con due proprietà `@Parent` e zero o più campi aggiuntivi.

### Query

Si può accedere al contesto del database utilizzando `req.db` nei route handler.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` è stato rinominato in `Database`.

Ora i key path ai campi hanno il prefisso `$` per specificare che si tratta del wrapper e non del valore del campo.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migrazioni

Le migrazioni devono essere scritte manualmente e non si basano più sul concetto di reflection:

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Ora le migrazioni sono tipate tramite stringe e non sono direttamente collegate ai modelli, utilizzano infatti il protocollo `Migration`.

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

I metodi `prepare` e `revert` non sono più statici.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

La creazione di un costruttore di schema è fatta tramite un metodo su `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Usa builder.
- }
+ var builder = database.schema("Galaxy")
+ // Usa builder.
```

I metodi `create`, `update` e `delete` sono metodi del costruttore di schema e assomigliano al funzionamento di un costruttore di query.

La definizione dei campi è tipata tramite stringhe e usa il seguente pattern: 

```swift
field(<name>, <type>, <constraints>)
```

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

La costruzione degli schemi può essere concatenata come un costruttore di query: 

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Configurazione di Fluent

`DatabasesConfig` è stato sostituito da `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` è stato sostituito da `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repository

Dal momento che è cambiato il modo in cui funzionano i servizi, anche la struttura delle Repository è cambiata. Servirà comunque un protocollo come `UserRepository`, ma invece di creare una `final class` che implementi il protocollo, basta creare una `struct`.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

Si può rimuovere l'utilizzo di `ServiceType`, dal momento che non esiste più. 

```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

Si può invece creare una `UserRepositoryFactory`:
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```

Questa struct ha la responsabilità di ritornare una `UserRepository` per una `Request`.

Il prossimo passo è quello di estendere l'`Application` con una proprietà computata che ritorna una `UserRepository`:

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

Per utilizzare l'effettiva repository all'interno di un route handler:

```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

L'ultimo passo è quello di specificare la factory nel metodo `configure`:

```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

Si può ora accedere alla repository nei route handler con `req.users.all()` e si può facilmente sostituire la repository con una simulata per i test. Basta creare un nuovo file `TestUserRepository`:
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

Si può usare la repository in questo modo:
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
