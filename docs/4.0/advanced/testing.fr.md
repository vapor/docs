# Tester

## VaporTesting

Vapor contient un module nommé `VaporTesting` fournissant des outils d'aide aux tests basés sur `Swift Testing`. Ces outils vous permettent d'envoyer des requêtes de test à votre application Vapor de façon automatisée ou à travers un vrai serveur HTTP.

!!! Note
    Pour les projets les plus récents ou pour les équipes migrant vers Swift concurrency, nous recommandons fortement `Swift Testing` par rapport à `XCTest`.

### Premiers pas

Pour utiliser le module `VaporTesting`, assurez-vous de l'ajouter à la target de test de votre package.

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

!!! Attention
    Assurez-vous d'importer le module de test, sans quoi vous vous exposez à des échecs de tests Vapor qui ne seront pas correctement rapportés.

Ensuite, ajoutez `import VaporTesting` et `import Testing` en haut de vos fichiers de tests. Créez des structs avec un nom de `@Suite` pour commencer à écrire vos cas de test. 

```swift
@testable import App
import VaporTesting
import Testing

@Suite("Tests applicatifs")
struct AppTests {
    @Test("Déclaration d'un test")
    func someTest() async throws {
        // Un test ici.
    }
}
```

Chaque fonctionnée marquée par `@Test` s'exécutera automatiquement lorsque votre application sera testée.

Pour forcer une exécution sérialisée des tests (i.e., lors de tests avec une base de données), indiquez l'option `.serialized` dans la déclaration de la suite de tests :

```swift
@Suite("Tests applicatifs avec base de données", .serialized)
```

### Application testable

Pour fournir une approche rationalisée et standardisée des méthodes de préparation et nettoyage des tests, `VaporTesting` expose la fonction `withApp`. Cette méthode encapsule la gestion du cycle de vie de l'instance de l'objet `Application`, permettant d'assurer que celle-ci est correctement initialisée, configurée, et arrêtée pour chaque test.

Fournissez la méthode `configure(_:)` de votre application à la fonction `withApp` pour que toutes vos routes soient correctement enregistrées :

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // Votre test sera codé ici.
    }
}
```

#### Envoi de requête

Pour envoyer une requête de test à votre application, utilisez la méthode privée `withApp` et, à l'intérieur, utilisez la méthode `app.testing().test()` :

```swift
@Test("Test de la route Hello World")
func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

Les deux premiers paramètres sont la méthode HTTP et l'URL à requêter. La closure finale reçoit la réponse HTTP que vous pouvez tester avec la macro `#expect`.

Pour des requêtes plus complexes, vous pouvez fournir une closure `beforeRequest` pour personnaliser les entêtes ou encodet du contentu. L'[API Contenu](../basics/content.md) de Vapor est disponible aussi bien pour les requêtes de test que les réponses obtenues.

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

#### Approches de test

L'API de test de Vapor permet l'envoi de requêtes de test soit programmatiquement, soit via un vrai server HTTP. Vous pouvez indiquer à la méthode `testing` laquelle de ces deux approches vous souhaitez utiliser.

```swift
// Approche programmatique.
app.testing(method: .inMemory).test(...)

// Exécution des tests à travers un serveur HTTP.
app.testing(method: .running).test(...)
```

L'approche programmatique est l'approche par défaut avec la valeur `inMemory`.

L'option `running` permet de configurer un port à utiliser. Par défaut, c'est le `8080`.

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### Tests d'intégration avec base de données

Configurez une base de données spécifique pour vos tests, afin de vous assurez que la base de données de production ne soit jamais utilisée pendant vos tests. Par exemple, si vous utilisez SQLite, vous pourriez configurer votre base de données dans la fonction `configure(_:)` comme ceci :

```swift
public func configure(_ app: Application) async throws {
    // D'autres configurations...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! Attention
    Assurez-vous que les tests s'exécutent bien sur la bonne base de données, pour éviter d'écraser accidentellement des données que vous ne souhaiteriez pas perdre.

Vous pouvez ensuite améliorer vos tests en utilisant `autoMigrate()` et `autoRevert()` pour gérer le schéma de la base de données et le cycle de vie des données au cours des tests. Pour cela, vous devriez créer votre propre fonction `withAppIncludingDB` qui ajoute la partie base de données à vos tests :

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

Puis dans vos tests, l'utiliser comme ceci :
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

En combinant ces méthodes, vous vous assurerez que chaque test démarre avec une base de données neuve et cohérente, rendant vos tests plus fiables, et réduisant les possibilités de faux positifs ou négatifs causés par des données qui traînent.


## XCTVapor

Vapor contient un module nommé `XCTVapor` fournissant des outils d'aide aux tests basés sur `XCTest`. Ces outils vous permettent d'envoyer des requêtes de test à votre application Vapor de façon automatisée ou à travers un vrai serveur HTTP.

### Premiers pas

Pour utiliser le module `XCTVapor`, assurez-vous de l'ajouter à la target de test de votre package.

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

Ensuite, ajoutez `import XCTVapor` en haut de vos fichiers de tests. Créez des classes qui étendent `XCTestCase` pour écrire vos cas de test.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // Un test ici.
    }
}
```

Chaque fonction commençant par `test` s'exécutera automatiquement lorsque votre application sera testée.

### Application testable

Initialisez une instance de l'objet `Application` qui utilise l'environnement `.testing`. Vous devez appeler `app.shutdown()` avant que cette instance ne se dé-initialise.  

L'appel à shutdown est nécessaire pour aider à libérer les ressources attribuées à l'application. Il est particulièrement important de libérer les processus réservés lors du démarrage. Si vous n'appelez pas `shutdown()` sur l'application après chaque test unitaire, vous pourriez constater des crashs dans vos suites de tests indiquant "precondition failure" au moment d'allouer des processus à une nouvelle instance d'objet `Application`.

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Passez l'instance de votre `Application` à la méthode `configure(_:)` de votre package pour appliquer votre configuration. Toute configuration spécifique aux tests pourra être appliquée plus tard.

#### Envoi de requête

Pour envoyer une requête de test à votre application, utilisez la méthode `test`.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

Les deux premiers paramètres sont la méthode HTTP et l'URL à requêter. La closure finale reçoit la réponse HTTP que vous pouvez tester grâce aux méthodes `XCTAssert`.

Pour des requêtes plus complexes, vous pouvez fournir une closure `beforeRequest` pour personnaliser les entêtes ou encodet du contenu. L'[API Contenu](../basics/content.md) de Vapor est disponible aussi bien sur les requêtes de test que les réponses.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### Approches de test

L'API de test de Vapor permet l'envoi de requêtes de test soit programmatiquement, soit via un vrai server HTTP. Vous pouvez indiquer à la méthode `testable` laquelle de ces deux approches vous souhaitez utiliser.

```swift
// Approche programmatique.
app.testable(method: .inMemory).test(...)

// Exécution des tests à travers un serveur HTTP.
app.testable(method: .running).test(...)
```

L'approche programmatique est l'approche par défaut avec la valeur `inMemory`.

L'option `running` permet de configurer un port à utiliser. Par défaut, c'est le `8080`.

```swift
.running(port: 8123)
```
