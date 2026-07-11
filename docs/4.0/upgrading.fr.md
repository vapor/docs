# Mettre à jour vers 4.0

Ce guide vous montre comment mettre à jour un projet Vapor 3.x existant vers 4.x. Ce guide tente de couvrir tous les packages officiels de Vapor ainsi que quelques providers couramment utilisés. Si vous remarquez quelque chose de manquant, le [chat d'équipe de Vapor](https://discord.gg/vapor) est un excellent endroit pour demander de l'aide. Les issues et pull requests sont également appréciées.

## Dépendances

Pour utiliser Vapor 4, vous aurez besoin de Xcode 11.4 et macOS 10.15 ou supérieur.

La section Installation de la documentation détaille l'installation des dépendances.

## Package.swift

La première étape pour mettre à jour vers Vapor 4 consiste à mettre à jour les dépendances de votre package. Voici un exemple de fichier Package.swift mis à jour. Vous pouvez également consulter le [Package.swift du template](https://github.com/vapor/template/blob/main/Package.swift) mis à jour.

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

Tous les packages qui ont été mis à jour pour Vapor 4 verront leur numéro de version majeure incrémenté de un.

!!! warning
    L'identifiant de pré-version `-rc` est utilisé car certains packages de Vapor 4 n'ont pas encore été officiellement publiés.

### Anciens packages

Certains packages de Vapor 3 ont été dépréciés, tels que :

- `vapor/auth` : Désormais inclus dans Vapor.
- `vapor/core` : Absorbé dans plusieurs modules. 
- `vapor/crypto` : Remplacé par SwiftCrypto (désormais inclus dans Vapor).
- `vapor/multipart` : Désormais inclus dans Vapor.
- `vapor/url-encoded-form` : Désormais inclus dans Vapor.
- `vapor-community/vapor-ext` : Désormais inclus dans Vapor.
- `vapor-community/pagination` : Désormais intégré à Fluent.
- `IBM-Swift/LoggerAPI` : Remplacé par SwiftLog.

### Dépendance Fluent

`vapor/fluent` doit désormais être ajouté comme dépendance séparée dans votre liste de dépendances et vos targets. Tous les packages spécifiques à une base de données ont désormais le suffixe `-driver` pour rendre explicite la dépendance à `vapor/fluent`.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### Plateformes

Les manifestes de package de Vapor prennent désormais explicitement en charge macOS 10.15 et supérieur. Cela signifie que votre package devra également spécifier la prise en charge des plateformes. 

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor pourra ajouter d'autres plateformes prises en charge à l'avenir. Votre package peut prendre en charge n'importe quel sous-ensemble de ces plateformes tant que le numéro de version est égal ou supérieur aux exigences de version minimale de Vapor. 

### Xcode

Vapor 4 utilise le support natif de SPM de Xcode 11. Cela signifie que vous n'avez plus besoin de générer de fichiers `.xcodeproj`. Ouvrir le dossier de votre projet dans Xcode reconnaîtra automatiquement SPM et récupérera les dépendances. 

Vous pouvez ouvrir votre projet nativement dans Xcode en utilisant `vapor xcode` ou `open Package.swift`. 

Une fois que vous avez mis à jour Package.swift, il se peut que vous deviez fermer Xcode et supprimer les dossiers suivants depuis la racine du projet :

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Une fois que vos packages mis à jour se sont résolus avec succès, vous devriez voir des erreurs de compilation — probablement pas mal. Ne vous inquiétez pas ! Nous allons vous montrer comment les corriger.

## Run

La première chose à faire est de mettre à jour le fichier `main.swift` de votre module Run au nouveau format.

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

Le contenu du fichier `main.swift` remplace le fichier `app.swift` du module App, vous pouvez donc supprimer ce fichier.

## App 

Voyons comment mettre à jour la structure de base du module App.

### configure.swift

La méthode `configure` doit être modifiée pour accepter une instance d'`Application`. 

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

Voici un exemple de méthode configure mise à jour.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Appelée avant l'initialisation de votre application.
public func configure(_ app: Application) throws {
    // Sert les fichiers depuis le dossier `Public/`
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configure la base de données SQLite
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configure les migrations
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

Les changements de syntaxe pour configurer le routing, les middlewares, Fluent, et plus encore, sont mentionnés ci-dessous.

### boot.swift

Le contenu de `boot` peut être placé dans la méthode `configure` puisqu'elle accepte désormais l'instance de l'application.

### routes.swift

La méthode `routes` doit être modifiée pour accepter une instance d'`Application`.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

Plus d'informations sur les changements de syntaxe du routing sont mentionnées ci-dessous.

## Services

Les API de services de Vapor 4 ont été simplifiées pour vous permettre de découvrir et d'utiliser les services plus facilement. Les services sont désormais exposés sous forme de méthodes et de propriétés sur `Application` et `Request`, ce qui permet au compilateur de vous aider à les utiliser. 

Pour mieux comprendre cela, examinons quelques exemples.

```diff
// Change le port par défaut du serveur à 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

Au lieu d'enregistrer une `NIOServerConfig` auprès des services, la configuration du serveur est désormais exposée sous forme de simples propriétés sur Application pouvant être surchargées. 

```diff
// Enregistre le middleware cors
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // Crée une configuration de middleware _vide_
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

Au lieu de créer et d'enregistrer une `MiddlewareConfig` auprès des services, les middlewares sont désormais exposés comme une propriété sur Application à laquelle on peut en ajouter.

```diff
// Effectue une requête dans un gestionnaire de route.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Comme Application, Request expose également des services sous forme de simples propriétés et méthodes. Les services spécifiques à Request doivent toujours être utilisés à l'intérieur d'une closure de route.

Ce nouveau modèle de service remplace les types `Container`, `Service` et `Config` de Vapor 3. 

### Providers

Les providers ne sont plus nécessaires pour configurer des packages tiers. Chaque package étend désormais Application et Request avec de nouvelles propriétés et méthodes de configuration.

Regardons comment Leaf est configuré dans Vapor 4.

```diff
// Utilise Leaf pour le rendu des vues. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

Pour configurer Leaf, utilisez la propriété `app.leaf`.

```diff
// Désactive la mise en cache des vues de Leaf.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Environment

L'environnement actuel (production, development, etc.) est accessible via `app.environment`. 

### Services personnalisés

Les services personnalisés conformes au protocole `Service` et enregistrés dans le conteneur dans Vapor 3 peuvent désormais être exprimés comme des extensions d'Application ou de Request.

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

Ce service peut ensuite être accédé en utilisant l'extension au lieu de `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Providers personnalisés

La plupart des services personnalisés peuvent être implémentés à l'aide d'extensions comme montré dans la section précédente. Cependant, certains providers avancés peuvent avoir besoin de s'accrocher au cycle de vie de l'application ou d'utiliser des propriétés stockées.

Le nouvel assistant `Lifecycle` d'Application peut être utilisé pour enregistrer des gestionnaires de cycle de vie.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

Pour stocker des valeurs sur Application, vous pouvez utiliser le nouvel assistant `Storage`. 

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

L'accès à `app.storage` peut être enveloppé dans une propriété calculée modifiable pour créer une API concise.

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

Vapor 4 expose désormais directement les API asynchrones de SwiftNIO et ne tente plus de surcharger des méthodes comme `map` et `flatMap`, ni d'aliaser des types comme `EventLoopFuture`. Vapor 3 fournissait des surcharges et des alias pour la rétrocompatibilité avec les premières versions bêta publiées avant l'existence de SwiftNIO. Ceux-ci ont été supprimés pour réduire la confusion avec d'autres packages compatibles SwiftNIO et mieux suivre les recommandations de bonnes pratiques de SwiftNIO. 

### Changements de nommage asynchrone

Le changement le plus évident est que l'alias de type `Future` pour `EventLoopFuture` a été supprimé. Cela peut être corrigé assez facilement avec un rechercher-remplacer.

De plus, NIO ne prend pas en charge les labels `to:` que Vapor 3 avait ajoutés. Étant donné l'inférence de type améliorée de Swift 5.2, `to:` est de toute façon moins nécessaire maintenant.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Les méthodes préfixées par `new`, comme `newPromise`, ont été renommées en `make` pour mieux correspondre au style Swift.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` n'est plus disponible, mais les méthodes de NIO comme `mapError` et `flatMapErrorThrowing` fonctionneront à la place. 

La méthode globale `flatMap` de Vapor 3 pour combiner plusieurs futures n'est plus disponible. Elle peut être remplacée en utilisant la méthode `and` de NIO pour combiner plusieurs futures ensemble. 

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Faire quelque chose avec a et b.
}
```

### ByteBuffer

De nombreuses méthodes et propriétés qui utilisaient auparavant `Data` utilisent désormais le `ByteBuffer` de NIO. Ce type est un type de stockage d'octets plus puissant et performant. Vous pouvez en apprendre davantage sur son API dans la [documentation ByteBuffer de SwiftNIO](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer).

Pour convertir un `ByteBuffer` en `Data`, utilisez :

```swift
Data(buffer.readableBytesView)
```

### map / flatMap qui lancent des erreurs

Le changement le plus difficile est que `map` et `flatMap` ne peuvent plus lancer d'erreurs (throw). `map` a une version qui lance des erreurs nommée (de façon quelque peu déroutante) `flatMapThrowing`. `flatMap`, en revanche, n'a pas d'équivalent qui lance des erreurs. Cela peut nécessiter de restructurer une partie de votre code asynchrone. 

Les maps qui ne lancent _pas_ d'erreurs devraient continuer à fonctionner correctement.

```swift
// Map qui ne lance pas d'erreur.
futureA.map { a in
    return b
}
```

Les maps qui lancent _effectivement_ des erreurs doivent être renommées en `flatMapThrowing`. 

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

Les flat-maps qui ne lancent _pas_ d'erreurs devraient continuer à fonctionner correctement.

```swift
// FlatMap qui ne lance pas d'erreur.
futureA.flatMap { a in
    return futureB
}
```

Au lieu de lancer une erreur à l'intérieur d'un flat-map, retournez une future en erreur. Si l'erreur provient d'une autre méthode qui lance des erreurs, l'erreur peut être capturée dans un do / catch et retournée comme une future.

```swift
// Retourne une erreur capturée comme une future.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

Les appels de méthodes qui lancent des erreurs peuvent également être refactorisés en `flatMapThrowing` et chaînés à l'aide de tuples.

```swift
// Méthode qui lance une erreur refactorisée en flatMapThrowing avec chaînage par tuple.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result est la valeur de doSomething.
    return futureB
}
```

## Routing

Les routes sont désormais enregistrées directement sur Application. 

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

Cela signifie que vous n'avez plus besoin d'enregistrer un router auprès des services. Passez simplement l'application à votre méthode `routes` et commencez à ajouter des routes. Toutes les méthodes disponibles sur `RoutesBuilder` sont disponibles sur `Application`. 

### Contenu synchrone

Le décodage du contenu de la requête est désormais synchrone.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

Ce comportement peut être surchargé en enregistrant les routes avec la stratégie de collecte du corps `.stream`. 

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Le corps de la requête est désormais asynchrone.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### Chemins séparés par des virgules

Les chemins doivent désormais être séparés par des virgules et ne pas contenir `/`, par souci de cohérence. 

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Gère la requête.
}
```

### Paramètres de route

Le protocole `Parameter` a été supprimé au profit de paramètres explicitement nommés. Cela évite les problèmes de paramètres dupliqués et de récupération non ordonnée des paramètres dans les middlewares et gestionnaires de route.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

L'utilisation des paramètres de route avec les modèles est mentionnée dans la section Fluent.

## Middleware

`MiddlewareConfig` a été renommé en `MiddlewareConfiguration` et est désormais une propriété sur Application. Vous pouvez ajouter des middlewares à votre app en utilisant `app.middleware`. 

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

Les middlewares ne peuvent plus être enregistrés par leur nom de type. Initialisez d'abord le middleware avant de l'enregistrer.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

Pour supprimer tous les middlewares par défaut, définissez `app.middleware` avec une configuration vide en utilisant :

```swift
app.middleware = .init()
```

## Fluent

L'API de Fluent est désormais agnostique de la base de données. Vous pouvez importer simplement `Fluent`.

```diff
- import FluentMySQL
+ import Fluent
```

### Modèles

Tous les modèles utilisent désormais le protocole `Model` et doivent être des classes.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

Tous les champs sont déclarés à l'aide des property wrappers `@Field` ou `@OptionalField`. 

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

L'ID d'un modèle doit être défini à l'aide du property wrapper `@ID`.

```diff
+ @ID(key: .id)
var id: UUID?
```

Les modèles utilisant un identifiant avec une clé ou un type personnalisé doivent utiliser `@ID(custom:)`.

Tous les modèles doivent avoir leur nom de table ou de collection défini statiquement.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

Tous les modèles doivent désormais avoir un initialiseur vide. Puisque toutes les propriétés utilisent des property wrappers, celui-ci peut être vide.

```diff
final class Planet: Model {
+   init() { }
}
```

Les méthodes `save`, `update` et `create` d'un modèle ne retournent plus l'instance du modèle.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

Les modèles ne peuvent plus être utilisés comme composants de chemin de route. Utilisez `find` et `req.parameters.get` à la place.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` a été renommé en `Model.IDValue`. 

Les timestamps des modèles sont désormais déclarés à l'aide du property wrapper `@Timestamp`.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relations

Les relations sont désormais définies à l'aide de property wrappers.

Les relations parent utilisent le property wrapper `@Parent` et contiennent en interne la propriété de champ. La clé passée à `@Parent` doit être le nom du champ stockant l'identifiant dans la base de données.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Les relations children utilisent le property wrapper `@Children` avec un key path vers le `@Parent` associé.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Les relations siblings utilisent le property wrapper `@Siblings` avec des key paths vers le modèle pivot.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Les pivots sont désormais des modèles normaux conformes à `Model`, avec deux relations `@Parent` et zéro ou plusieurs champs supplémentaires.

### Query

Le contexte de la base de données est désormais accessible via `req.db` dans les gestionnaires de route.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` a été renommé en `Database`.

Les key paths vers les champs sont désormais préfixés par `$` pour spécifier le property wrapper au lieu de la valeur du champ.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migrations

Les modèles ne prennent plus en charge les migrations automatiques basées sur la réflexion. Toutes les migrations doivent désormais être écrites manuellement. 

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Les migrations sont désormais typées sous forme de chaînes et découplées des modèles, et utilisent le protocole `Migration`. 

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

Les méthodes `prepare` et `revert` ne sont plus statiques.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

La création d'un schema builder se fait via une méthode d'instance sur `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Utilise builder.
- }
+ var builder = database.schema("Galaxy")
+ // Utilise builder.
```

Les méthodes `create`, `update` et `delete` sont désormais appelées sur le schema builder, de manière similaire au fonctionnement du query builder.

Les définitions de champs sont désormais typées sous forme de chaînes et suivent le pattern :

```swift
field(<name>, <type>, <constraints>)
```

Voir l'exemple ci-dessous.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

La construction de schéma peut désormais être chaînée comme le query builder.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Configuration de Fluent

`DatabasesConfig` a été remplacé par `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` a été remplacé par `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repositories

La façon dont les services fonctionnent dans Vapor 4 ayant changé, cela signifie également que la façon de faire des repositories de base de données a changé. Vous avez toujours besoin d'un protocole comme `UserRepository`, mais au lieu de faire conformer une `final class` à ce protocole, vous devriez plutôt utiliser une `struct`.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

Vous devriez également supprimer la conformité à `ServiceType` car celle-ci n'existe plus dans Vapor 4. 
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

Vous devriez plutôt créer une `UserRepositoryFactory` :
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
Cette factory est responsable de retourner un `UserRepository` pour une `Request`.

L'étape suivante consiste à ajouter une extension à `Application` pour spécifier votre factory :
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

Pour utiliser le repository réel à l'intérieur d'une `Request`, ajoutez cette extension à `Request` :
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

La dernière étape consiste à spécifier la factory dans `configure.swift`
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

Vous pouvez désormais accéder à votre repository dans vos gestionnaires de route avec : `req.users.all()` et remplacer facilement la factory dans les tests.
Si vous souhaitez utiliser un repository simulé (mock) dans les tests, créez d'abord un `TestUserRepository`
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

Vous pouvez désormais utiliser ce repository simulé dans vos tests comme suit :
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
