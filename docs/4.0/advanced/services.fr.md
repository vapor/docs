# Services

`Application` et `Request` de Vapor sont conçus pour être étendus par votre application et par des packages tiers. Les nouvelles fonctionnalités ajoutées à ces types sont souvent appelées services.

## Lecture seule

Le type de service le plus simple est en lecture seule. Ces services consistent en des variables calculées ou des méthodes ajoutées à l'application ou à la requête.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

Les services en lecture seule peuvent dépendre de tout service préexistant, comme `client` dans cet exemple. Une fois l'extension ajoutée, votre service personnalisé peut être utilisé comme n'importe quelle autre propriété sur la requête.

```swift
req.myAPI.foos()
```

## Modifiable

Les services qui ont besoin d'un état ou d'une configuration peuvent utiliser le stockage (`storage`) d'`Application` et de `Request` pour stocker des données. Supposons que vous vouliez ajouter la structure suivante `MyConfiguration` à votre application.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Pour utiliser le stockage, vous devez déclarer une `StorageKey`.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Il s'agit d'une structure vide avec un alias de type `Value` précisant quel type est stocké. En utilisant un type vide comme clé, vous pouvez contrôler quel code est capable d'accéder à votre valeur de stockage. Si le type est interne (internal) ou privé (private), seul votre code pourra modifier la valeur associée dans le stockage.

Enfin, ajoutez une extension à `Application` pour lire et définir la structure `MyConfiguration`.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

Une fois l'extension ajoutée, vous pouvez utiliser `myConfiguration` comme une propriété normale sur `Application`.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Cycle de vie

`Application` de Vapor vous permet d'enregistrer des gestionnaires de cycle de vie (lifecycle handlers). Ceux-ci vous permettent de vous brancher sur des événements comme le démarrage (boot) et l'arrêt (shutdown).

```swift
// Affiche hello pendant le démarrage.
struct Hello: LifecycleHandler {
    // Appelé avant le démarrage de l'application.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Appelé après le démarrage de l'application.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Appelé avant l'arrêt de l'application.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Ajoute le gestionnaire de cycle de vie.
app.lifecycle.use(Hello())
```

## Verrous

`Application` de Vapor inclut des fonctionnalités pratiques pour synchroniser du code à l'aide de verrous (locks). En déclarant une `LockKey`, vous pouvez obtenir un verrou unique et partagé pour synchroniser l'accès à votre code.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Faites quelque chose.
}
```

Chaque appel à `lock(for:)` avec la même `LockKey` renverra le même verrou. Cette méthode est thread-safe.

Pour un verrou à l'échelle de l'application, vous pouvez utiliser `app.sync`.

```swift
app.sync.withLock {
    // Faites quelque chose.
}
```

## Request

Les services destinés à être utilisés dans les gestionnaires de routes (route handlers) doivent être ajoutés à `Request`. Les services de requête doivent utiliser le logger et l'event loop de la requête. Il est important qu'une requête reste sur la même event loop, sinon une assertion sera déclenchée lorsque la réponse sera retournée à Vapor.

Si un service doit quitter l'event loop de la requête pour effectuer un travail, il doit veiller à revenir sur l'event loop avant de terminer. Cela peut être fait en utilisant `hop(to:)` sur `EventLoopFuture`.

Les services de requête ayant besoin d'accéder aux services de l'application, comme les configurations, peuvent utiliser `req.application`. Faites attention à la thread-safety lorsque vous accédez à l'application depuis un gestionnaire de route. En général, seules des opérations de lecture doivent être effectuées par les requêtes. Les opérations d'écriture doivent être protégées par des verrous.
