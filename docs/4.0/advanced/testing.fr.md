# Tests

## VaporTesting

Vapor inclut un module nommé `VaporTesting` qui fournit des outils d'aide aux tests basés sur `Swift Testing`. Ces outils vous permettent d'envoyer des requêtes de test à votre application Vapor, que ce soit de manière programmatique ou en passant par un serveur HTTP réel.

!!! note
    Pour les nouveaux projets ou les équipes adoptant la concurrence Swift, `Swift Testing` est fortement recommandé par rapport à `XCTest`.

### Pour commencer

Pour utiliser le module `VaporTesting`, assurez-vous qu'il a été ajouté à la cible de test de votre paquet.

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
    Assurez-vous d'utiliser le module de test correspondant, car ne pas le faire peut entraîner un rapport incorrect des échecs de tests Vapor.

Ensuite, ajoutez `import VaporTesting` et `import Testing` en haut de vos fichiers de test. Créez des structs avec un nom `@Suite` pour écrire des cas de test.

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

Chaque fonction marquée avec `@Test` s'exécutera automatiquement lorsque votre application est testée.

Pour vous assurer que vos tests s'exécutent de manière sérialisée (par exemple, lors de tests avec une base de données), incluez l'option `.serialized` dans la déclaration de la suite de tests :

```swift
@Suite("App Tests with DB", .serialized)
```

### Application testable

Pour fournir une configuration et un démontage des tests simplifiés et standardisés, `VaporTesting` propose la fonction d'aide `withApp`. Cette méthode encapsule la gestion du cycle de vie de l'instance `Application`, garantissant que l'application est correctement initialisée, configurée et arrêtée pour chaque test.

Passez la méthode `configure(_:)` de votre application à la fonction d'aide `withApp` pour vous assurer que toutes vos routes sont correctement enregistrées :

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### Envoyer une requête

Pour envoyer une requête de test à votre application, utilisez la méthode privée `withApp` et, à l'intérieur, utilisez la méthode `app.testing().test()` :

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

Les deux premiers paramètres sont la méthode HTTP et l'URL de la requête. La fermeture (closure) finale accepte la réponse HTTP, que vous pouvez vérifier à l'aide de la macro `#expect`.

Pour des requêtes plus complexes, vous pouvez fournir une fermeture `beforeRequest` pour modifier les en-têtes ou encoder du contenu. L'[API Content](../basics/content.md) de Vapor est disponible à la fois sur la requête de test et sur la réponse.

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

#### Méthode de test

L'API de test de Vapor permet d'envoyer des requêtes de test de manière programmatique ou via un serveur HTTP réel. Vous pouvez indiquer la méthode que vous souhaitez utiliser grâce à la méthode `testing`.

```swift
// Use programmatic testing.
app.testing(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testing(method: .running).test(...)
```

L'option `inMemory` est utilisée par défaut.

L'option `running` permet de passer un port spécifique à utiliser. Par défaut, le port `8080` est utilisé.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Tests d'intégration de base de données

Configurez la base de données spécifiquement pour les tests afin de vous assurer que votre base de données de production n'est jamais utilisée pendant les tests. Par exemple, si vous utilisez SQLite, vous pourriez configurer votre base de données dans la fonction `configure(_:)` comme suit :

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
    Assurez-vous d'exécuter vos tests sur la bonne base de données, afin d'éviter d'écraser accidentellement des données que vous ne voulez pas perdre.

Vous pouvez ensuite améliorer vos tests en utilisant `autoMigrate()` et `autoRevert()` pour gérer le schéma de la base de données et le cycle de vie des données pendant les tests. Pour ce faire, vous devriez créer votre propre fonction d'aide `withAppIncludingDB` qui inclut le schéma de base de données et les cycles de vie des données :

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

Puis utilisez cette fonction d'aide dans vos tests :
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

En combinant ces méthodes, vous pouvez vous assurer que chaque test commence avec un état de base de données propre et cohérent, ce qui rend vos tests plus fiables et réduit la probabilité de faux positifs ou de faux négatifs causés par des données persistantes.


## XCTVapor

Vapor inclut un module nommé `XCTVapor` qui fournit des outils d'aide aux tests basés sur `XCTest`. Ces outils vous permettent d'envoyer des requêtes de test à votre application Vapor, que ce soit de manière programmatique ou en passant par un serveur HTTP réel.

### Pour commencer

Pour utiliser le module `XCTVapor`, assurez-vous qu'il a été ajouté à la cible de test de votre paquet.

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

Ensuite, ajoutez `import XCTVapor` en haut de vos fichiers de test. Créez des classes étendant `XCTestCase` pour écrire des cas de test.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Test here.
    }
}
```

Chaque fonction commençant par `test` s'exécutera automatiquement lorsque votre application est testée.

### Application testable

Initialisez une instance d'`Application` en utilisant l'environnement `.testing`. Vous devez appeler `app.shutdown()` avant que cette application ne soit désinitialisée.

L'arrêt (shutdown) est nécessaire pour aider à libérer les ressources que l'application a réclamées. Il est particulièrement important de libérer les threads que l'application demande au démarrage. Si vous n'appelez pas `shutdown()` sur l'application après chaque test unitaire, il se peut que votre suite de tests plante avec un échec de précondition lors de l'allocation de threads pour une nouvelle instance d'`Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Passez l'`Application` à la méthode `configure(_:)` de votre paquet pour appliquer votre configuration. Toute configuration propre aux tests peut être appliquée par la suite.

#### Envoyer une requête

Pour envoyer une requête de test à votre application, utilisez la méthode `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

Les deux premiers paramètres sont la méthode HTTP et l'URL de la requête. La fermeture (closure) finale accepte la réponse HTTP, que vous pouvez vérifier à l'aide des méthodes `XCTAssert`.

Pour des requêtes plus complexes, vous pouvez fournir une fermeture `beforeRequest` pour modifier les en-têtes ou encoder du contenu. L'[API Content](../basics/content.md) de Vapor est disponible à la fois sur la requête de test et sur la réponse.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Méthode testable

L'API de test de Vapor permet d'envoyer des requêtes de test de manière programmatique ou via un serveur HTTP réel. Vous pouvez indiquer la méthode que vous souhaitez utiliser grâce à la méthode `testable`.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

L'option `inMemory` est utilisée par défaut.

L'option `running` permet de passer un port spécifique à utiliser. Par défaut, le port `8080` est utilisé.

```swift
.running(port: 8123)
```
