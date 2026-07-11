# Files d'attente (Queues)

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) est un système de files d'attente en Swift pur qui vous permet de déléguer la responsabilité d'une tâche à un worker secondaire.

Voici quelques exemples de tâches pour lesquelles ce package fonctionne bien :

- Envoyer des emails en dehors du thread de requête principal
- Effectuer des opérations de base de données complexes ou de longue durée
- Garantir l'intégrité et la résilience des jobs
- Accélérer le temps de réponse en retardant les traitements non critiques
- Planifier des jobs pour qu'ils s'exécutent à un moment précis

Ce package est similaire à [Ruby Sidekiq](https://github.com/mperham/sidekiq). Il fournit les fonctionnalités suivantes :

- Gestion sûre des signaux `SIGTERM` et `SIGINT` envoyés par les hébergeurs pour indiquer un arrêt, un redémarrage ou un nouveau déploiement.
- Différentes priorités de files d'attente. Par exemple, vous pouvez spécifier qu'un job de file d'attente s'exécute sur la file d'attente des emails et qu'un autre s'exécute sur la file d'attente de traitement des données.
- Implémente le processus de file d'attente fiable pour aider à gérer les échecs inattendus.
- Inclut une fonctionnalité `maxRetryCount` qui répète le job jusqu'à ce qu'il réussisse, dans la limite d'un nombre spécifié.
- Utilise NIO pour exploiter tous les cœurs et EventLoops disponibles pour les jobs.
- Permet aux utilisateurs de planifier des tâches répétitives

Queues dispose actuellement d'un driver officiellement pris en charge qui s'interface avec le protocole principal :

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues dispose également de drivers communautaires :

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip
    Vous ne devriez pas installer le package `vapor/queues` directement, sauf si vous développez un nouveau driver. Installez plutôt l'un des packages de driver.

## Pour commencer

Voyons comment vous pouvez commencer à utiliser Queues.

### Package

La première étape pour utiliser Queues consiste à ajouter l'un des drivers en tant que dépendance de votre projet dans votre fichier manifeste de package SwiftPM. Dans cet exemple, nous utiliserons le driver Redis.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // Other dependencies
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Si vous modifiez le manifeste directement dans Xcode, celui-ci détectera automatiquement les changements et récupérera la nouvelle dépendance lors de l'enregistrement du fichier. Sinon, depuis le terminal, exécutez `swift package resolve` pour récupérer la nouvelle dépendance.

### Configuration

L'étape suivante consiste à configurer Queues dans `configure.swift`. Nous utiliserons la bibliothèque Redis comme exemple :

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Enregistrer un `Job`

Après avoir modélisé un job, vous devez l'ajouter à votre section de configuration comme ceci :

```swift
// Register jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Exécuter des workers en tant que processus

Pour démarrer un nouveau worker de file d'attente, exécutez `swift run App queues`. Vous pouvez également spécifier un type de worker particulier à exécuter : `swift run App queues --queue emails`.

!!! tip
    Les workers doivent rester actifs en production. Consultez votre hébergeur pour savoir comment maintenir des processus de longue durée actifs. Heroku, par exemple, permet de spécifier des dynos "worker" comme ceci dans votre Procfile : `worker: Run queues`. Une fois cela en place, vous pouvez démarrer les workers depuis l'onglet Dashboard/Resources, ou avec `heroku ps:scale worker=1` (ou tout autre nombre de dynos souhaité).

### Exécuter des workers dans le même processus

Pour exécuter un worker dans le même processus que votre application (plutôt que de démarrer un serveur entièrement séparé pour le gérer), appelez les méthodes utilitaires sur `Application` :

```swift
try app.queues.startInProcessJobs(on: .default)
```

Pour exécuter des jobs planifiés dans le processus, appelez la méthode suivante :

```swift
try app.queues.startScheduledJobs()
```

!!! warning
    Si vous ne démarrez pas le worker de file d'attente, que ce soit via la ligne de commande ou le worker interne au processus, les jobs ne seront pas distribués.

## Le protocole `Job`

Les jobs sont définis par le protocole `Job` ou `AsyncJob`.

### Modéliser un objet `Job` :

```swift
import Vapor
import Foundation
import Queues

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // This is where you would send the email
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // If you don't want to handle errors you can simply return a future. You can also omit this function entirely.
        return context.eventLoop.future()
    }
}
```

Si vous utilisez `async`/`await`, vous devriez utiliser `AsyncJob` :

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // This is where you would send the email
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // If you don't want to handle errors you can simply return. You can also omit this function entirely.
    }
}
```

!!! info
    Assurez-vous que votre type `Payload` implémente le protocole `Codable`.

!!! tip
    N'oubliez pas de suivre les instructions de la section **Pour commencer** pour ajouter ce job à votre fichier de configuration.

## Distribuer des jobs

Pour distribuer un job de file d'attente, vous devez avoir accès à une instance d'`Application` ou de `Request`. Vous distribuerez le plus souvent des jobs à l'intérieur d'un gestionnaire de route :

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

Si, au lieu de cela, vous devez distribuer un job depuis un contexte où l'objet `Request` n'est pas disponible (comme, par exemple, depuis une `Command`), vous devrez utiliser la propriété `queues` de l'objet `Application`, comme ceci :

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message")
            )
    }
}
```

### Définir `maxRetryCount`

Les jobs se relancent automatiquement en cas d'erreur si vous spécifiez un `maxRetryCount`. Par exemple :

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### Spécifier un délai

Les jobs peuvent également être configurés pour ne s'exécuter qu'après qu'une certaine `Date` soit passée. Pour spécifier un délai, transmettez une `Date` au paramètre `delayUntil` de `dispatch` :

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

Si un job est retiré de la file d'attente (dequeued) avant l'expiration de son paramètre de délai, il sera remis en file d'attente par le driver.

### Spécifier une priorité

Les jobs peuvent être répartis en différents types/priorités de files d'attente selon vos besoins. Par exemple, vous pouvez souhaiter ouvrir une file d'attente `email` et une file d'attente `background-processing` pour trier les jobs.

Commencez par étendre `QueueName` :

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Vous pouvez également définir un `workerCount` par file d'attente lors de la création d'un `QueueName` :

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

Définir `workerCount: 1` fait en sorte que cette file d'attente traite les jobs de manière consécutive, ce qui est utile lorsque l'ordre des jobs importe.

Ensuite, spécifiez le type de file d'attente lors de la récupération de l'objet `jobs` :

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// or

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "done"
}
```

Lorsque vous y accédez depuis l'objet `Application`, procédez comme suit :

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```

Si vous ne spécifiez pas de file d'attente, le job s'exécutera sur la file d'attente `default`. Assurez-vous de suivre les instructions de la section **Pour commencer** pour démarrer des workers pour chaque type de file d'attente.

## Planifier des jobs

Le package Queues vous permet également de planifier des jobs pour qu'ils s'exécutent à des moments précis.

!!! warning
    Les jobs planifiés ne fonctionnent que s'ils sont configurés avant le démarrage de l'application, par exemple dans `configure.swift`. Ils ne fonctionneront pas dans des gestionnaires de route.

### Démarrer le worker du planificateur

Le planificateur nécessite qu'un processus de worker séparé soit en cours d'exécution, de manière similaire au worker de file d'attente. Vous pouvez démarrer le worker en exécutant cette commande :

```sh
swift run App queues --scheduled
```

!!! tip
    Les workers doivent rester actifs en production. Consultez votre hébergeur pour savoir comment maintenir des processus de longue durée actifs. Heroku, par exemple, permet de spécifier des dynos "worker" comme ceci dans votre Procfile : `worker: App queues --scheduled`

### Créer un `ScheduledJob`

Pour commencer, créez un nouveau `ScheduledJob` ou `AsyncScheduledJob` :

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Do some work here, perhaps queue up another job.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) async throws {
        // Do some work here, perhaps queue up another job.
    }
}
```

Ensuite, dans votre code de configuration, enregistrez le job planifié :

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

Le job de l'exemple ci-dessus s'exécutera chaque année, le 23 mai à 12h00.

!!! tip
    Le planificateur utilise le fuseau horaire de votre serveur.

### Méthodes de builder disponibles

Il existe deux styles d'API de planification :

- Les builders de type calendrier, qui renvoient des objets builder pour être chaînés.
- Les builders de type intervalle, qui exécutent des jobs à intervalle fixe.

Vous devriez continuer à construire une chaîne de planificateur de type calendrier jusqu'à ce que le compilateur ne vous signale plus d'avertissement concernant un résultat inutilisé. Voir ci-dessous toutes les méthodes disponibles :

| Fonction utilitaire | Modificateurs disponibles              | Description                                                                     |
|----------------------|----------------------------------------|----------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | Le mois pendant lequel exécuter le job. Renvoie un objet `Monthly` pour poursuivre la construction.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | Le jour du mois où exécuter le job. Renvoie un objet `Daily` pour poursuivre la construction.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | Le jour de la semaine où exécuter le job. Renvoie un objet `Daily`.               |
| `daily()`       | `at(_ time: Time)`                    | L'heure à laquelle exécuter le job. Méthode finale de la chaîne.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| L'heure et la minute auxquelles exécuter le job. Méthode finale de la chaîne.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | L'heure, la minute et la période auxquelles exécuter le job. Méthode finale de la chaîne |
| `hourly()`      | `at(_ minute: Minute)`                 | La minute à laquelle exécuter le job. Méthode finale de la chaîne.                      |
| `minutely()`    | `at(_ second: Second)`                 | La seconde à laquelle exécuter le job. Méthode finale de la chaîne.                      |

### Méthodes de builder par intervalle (`.every(...)`)

Le planificateur prend également en charge la planification à intervalle fixe avec les méthodes `.every(...)` :

| Fonction utilitaire | Description                                                                    |
|-----------------|--------------------------------------------------------------------------------|
| `every(seconds: Int)` | Exécute le job toutes les N secondes indiquées.                              |
| `every(minutes: Int)` | Exécute le job toutes les N minutes indiquées.                              |
| `every(hours: Int)`   | Exécute le job toutes les N heures indiquées.                                |
| `every(days: Int)`    | Exécute le job tous les N jours indiqués.                                 |
| `every(weeks: Int)`   | Exécute le job toutes les N semaines indiquées.                                |

Exemple :

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### Assistants disponibles

Queues est fourni avec des énumérations d'assistance pour faciliter la planification :

| Fonction utilitaire | Énumération d'assistance disponible                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

Pour utiliser l'énumération d'assistance, appelez le modificateur approprié sur la fonction utilitaire et transmettez la valeur. Par exemple :

```swift
// Every year in January
.yearly().in(.january)

// Every month on the first day
.monthly().on(.first)

// Every week on Sunday
.weekly().on(.sunday)

// Every day at midnight
.daily().at(.midnight)
```

## Délégués d'événements

Le package Queues vous permet de spécifier des objets `JobEventDelegate` qui recevront des notifications lorsque le worker effectue une action sur un job. Cela peut être utilisé à des fins de supervision, de mise en évidence d'informations, ou d'alerte.

Pour commencer, faites en sorte qu'un objet soit conforme à `JobEventDelegate` et implémentez les méthodes requises

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Called when the job is dispatched to the queue worker from a route
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job is placed in the processing queue and work begins
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job has finished processing and has been removed from the queue
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Called when the job has finished processing but had an error
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

Ensuite, ajoutez-le dans votre fichier de configuration :

```swift
app.queues.add(MyEventDelegate())
```

Il existe un certain nombre de packages tiers qui utilisent la fonctionnalité de délégué pour fournir des informations supplémentaires sur vos workers de file d'attente :

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Tests

Pour éviter les problèmes de synchronisation et garantir des tests déterministes, le package Queues fournit une bibliothèque `XCTQueue` ainsi qu'un driver `AsyncTestQueuesDriver` dédié aux tests, que vous pouvez utiliser comme suit :

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Override the driver being used for testing
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

Voir plus de détails dans [l'article de blog de Romain Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# Dépannage

Lorsque vous utilisez [queues-redis-driver](https://github.com/vapor/queues-redis-driver) avec un serveur compatible Redis basé sur un cluster, tel que Redis ou Valkey sur Amazon AWS, vous pourriez rencontrer ce message d'erreur : `CROSSSLOT Keys in request don't hash to the same slot`.

Cela ne se produit qu'en mode cluster, car Redis ou Valkey ne peut pas savoir avec certitude sur quel nœud du cluster stocker les données du job.

Pour corriger cela, ajoutez un [hash tag](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) aux noms de vos entrées de données de job en utilisant des accolades dans les noms :

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
