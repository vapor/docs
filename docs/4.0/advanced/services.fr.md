# Services

Les objets `Application` et `Request` de Vapor sont conçus pour être étendus par votre application et packages tiers. Les nouvelles fonctionnalités ajoutées à ces types sont souvent appelées services. 

## Lecture seule

Le type de service le plus basique est celui en lecture seule. Ces services sont constitués de variables calculées ou de méthodes qui s'ajoutent à l'application ou à la requête. 

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

Les services en lecture seule peuvent dépendre de n'importe quel autre service pré-existant, comme `client` dans l'exemple ci-dessus. Une fois l'extension ajoutée, votre service personnalisé peut être utilisé comme toute autre propriété de la requête.

```swift
req.myAPI.foos()
```

## Écriture

Les services qui ont besoin d'état ou de configuration peuvent utiliser le stoquage sur `Application` et `Request` pour écrire des données. Supposons que vous vouliez ajouter la struct `MyConfiguration` suivante à votre application.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Pour utiliser le stoquage, vous devez déclarer une clé de stoquage avec `StorageKey`. 

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Il s'agit d'une struct vide ayant un alias de type nommé `Value` permettant d'indiquer quel type stoquer. En utilisant un type vide en guide de clé, vous pouvez contrôler le code qui peut accéder à la valeur dans votre stoquage. Si ce type a la visibilité internal ou private, seul votre code pourra modifier la valeur associée au stoquage.

Enfin, ajoutez une extension à `Application` pour définir l'accès à la struct `MyConfiguration`.

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

Une fois l'extension ajoutée, vous pouvez utiliser `myConfiguration` comme une propriété normale sur l'objet `Application`.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Cycle de vie

L'objet `Application` de Vapor vous permet d'enregistrer des gestionnaires de cycle de vie. Ces objets vous permettent d'exécuter du code en réaction à des évènements tels que le démarrage ou l'arrêt de l'application.

```swift
// Affiche bonjour pendant le démarrage.
struct Hello: LifecycleHandler {
    // Appelé avant le démarrage de l'application.
    func willBoot(_ app: Application) throws {
        app.logger.info("Bonjour !")
    }

    // Appelé après le démarrage de l'application.
    func didBoot(_ app: Application) throws {
        app.logger.info("Le serveur est démarré.")
    }

    // Appelé avant l'extinction du serveur.
    func shutdown(_ app: Application) {
        app.logger.info("Au revoir !")
    }
}

// Ajout du gestionnaire de cycle de vie.
app.lifecycle.use(Hello())
```

## Verrous (Locks)

L'objet `Application` de Vapor expose des objets pour faciliter la synchronisation du code grâce à des locks. En déclarant un type `LockKey`, vous pouvez obtenir un lock unique et partagé pour synchroniser les accès à votre code. 

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Faire quelque-chose.
}
```

Chaque appel à `lock(for:)` avec la même clé `LockKey` retournera le même verrou. Cette méthode est thread-safe.

Pour un verrou global au niveau de l'application, vous pouvez utiliser `app.sync`. 

```swift
app.sync.withLock {
    // Faire quelque-chose.
}
```

## Requête

Les services prévus pour un usage dans les contrôleurs devraient être ajoutés à l'objet `Request`. Les services de requête devraient utiliser le logger et l'event-loop de la requête. Il est primordial qu'une requête reste sur le même event-loop sans quoi une assertion sera rencontrée lorsque la réponse reviendra à Vapor. 

Si un service doit quitter l'event-loop de la requête pour exécuter du travail, il devrait faire en sorte de revenir à l'event-loop initial avant la fin de son exécution. Cela peut se faire par la méthode `hop(to:)` sur les objets `EventLoopFuture`. 

Les services de requête qui ont besoin d'accéder à des services de l'application, tels que des configurations, peuvent utiliser `req.application`. Faites attention à prendre en compte la sécurité multi-processus lorsque vous accédez à l'application depuis une route. De façon générale, seules des opérations de lecture devraient être exécutées par des requêtes. Les opérations d'écriture doivent être protégées par des verrous. 