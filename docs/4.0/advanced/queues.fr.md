# Files d'attente

Les files d'attente de Vapor ([package Queues](https://github.com/vapor/queues)) sont un système de files vous permettant de déléguer du travail à un processus parallèle.

Voici quelques exemples de tâches pour lesquels ce package fonctionne bien :

- Envoi de mails en déhors du processus principal de la requête
- Exécution d'opérations complexes ou longues en base de données
- Assurer l'intégrité et la résilience d'une opération
- Améliorer le temps de réponse en déplaçant les opérations non critiques
- Planifier une tâche à un moment ultérieur

Ce package est similaire à [Ruby Sidekiq](https://github.com/mperham/sidekiq). Il fournit les fonctionnalités suivantes :

- Gestion sécurisée des signaux `SIGTERM` et `SIGINT` envoyés par les hébergeurs pour indiquer un arrêt, re-démarrage, ou nouveau déploiement.
- Différentes priorités de files. Par exemple, vous pouvez choisir d'envoyer une tâche sur la file des e-mails et une autre sur la file de calcul.
- Implémentation fiable de file d'attente pour faciliter la gestion des pannes.
- `maxRetryCount` permettant de relancer une tâche plusieurs fois jusqu'à sa réussite ou l'atteinte du nombre maximal de tentatives défini.
- Utilise NIO pour accéder à tous les coeurs de processeur et EventLoops pour la parallélisation des tâches.
- Permettre à l'utilisateur de planifier des tâches se répétant dans le temps.

Les files d'attente ont aujourd'hui un pilote officiel qui s'interface avec le protocole principal :

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Elles ont aussi des pilotes maintenus par la communauté :

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! Conseil
    Vous ne devriez pas installer le package `vapor/queues` directement, sauf si vous développez un nouveau pilote. Installez plutôt un des packages de pilote.

## Premiers pas

Voyons comment commencer à utiliser des files d'attente.

### Package

La première étape pour utiliser des files d'attente consiste à ajouter un des pilotes comme dépendance de votre projet dans le fichier manifeste SwiftPM de votre package. Dans cet exemple, nous utiliserons le pilote Redis.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// D'autres dépendances...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // D'autres dépendances...
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Si vous modifiez le manifeste dans Xcode, il détectera automatiquement les changements et récupérera les nouvelles dépendances quand vous enregistrerez le fichier. Sinon, depuis Terminal, lancez `swift package resolve` pour récupérer les nouvelles dépendances.

### Configuration

L'étape suivante est la configuration de l'API Queues dans `configure.swift`. Nous utiliserons Redis comme exemple :

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Enregistrer une tâche

Après avoir modélisé une tâche, vous devez l'ajouter à la section configuration de votre application comme ceci :

```swift
// Enregistrer les tâches
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Exécution de Workers en processus distinct

Pour démarrer un nouveau Worker de traitement de file, lancez `swift run App queues`. Vous pouvez aussi préciser un type de Worker particulier : `swift run App queues --queue emails`.

!!! Conseil
    Les Workers devraient toujours s'exécuter en continu sur l'environnement de production. Consultez votre hébergeur pour savoir combien de temps garder actif les processus à exécution longue. Heroku, par exemple, vous permet de marquer des instances comme "worker" comme ceci dans votre fichier Procfile : `worker: Run queues`. Avec cette configuration, vous pouvez démarrer des Workers depuis l'onglet Dashboard/Resources, ou avec la commande `heroku ps:scale worker=1` (ou votre nombre d'instances souhaité).

### Exécution de Workers in-process

Pour exécuter un Worker dans le même processus que votre application (plutôt que de démarrer tout un serveur séparé pour gérer une file), appelez cette méthode sur votre objet `Application` :

```swift
try app.queues.startInProcessJobs(on: .default)
```

Pour le traitement des tâches planifiées sur le même processus, appelez cette méthode :

```swift
try app.queues.startScheduledJobs()
```

!!! Attention
    Si vous ne démarrez pas un Worker de file, soit via ligne de commande soit in-process, vos tâches ne pourra pas être déléguées et traitées.

## Le protocole `Job`

Les tâches sont définies par les protocoles `Job` ou `AsyncJob`.

### Modéliser une tâche

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
        // C'est ici que serait codée la logique d'envoi d'e-mail
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // Si vous ne voulez pas gérer les erreurs, vous pouvez retourner un simple futur ou ne pas implémenter cette méthode.
        return context.eventLoop.future()
    }
}
```

Pour utiliser `async`/`await` vous devrez plutôt utiliser `AsyncJob` :

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // C'est ici que serait codée la logique d'envoi d'e-mail
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // Si vous ne voulez pas gérer les erreurs, vous pouvez retourner un simple futur ou ne pas implémenter cette méthode.
    }
}
```

!!! Info
    Assurez-vous que votre type `Payload` implémente le protocole `Codable`.

!!! Conseil
    N'oubliez pas de suivre les instructions de la section **Premiers pas** pour ajouter cette tâche à votre fichier de configuration.

## Délégation de tâches

Pour déléguer une tâche à une file d'attente, vous aurez besoin d'une instance `Application` ou `Request`. Il est probable que vous déléguiez vos tâches depuis vos contrôleurs :

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// ou

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

Si au contraire vous avez besoin de déléguer une tâche depuis un contexte où l'objet `Request` n'est pas disponible (comme par exemple depuis une `Commande`), vous devrez utiliser la propriété `queues` de l'objet `Application`, comme ceci :

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

Les tâches des files d'attente se ré-exécuteront automatiquement en cas d'erreur si vous spécifiez une valeur `maxRetryCount`. Par exemple :

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

// ou

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### Définir un délai

Vos tâches peuvent aussi être configurées pour s'exécuter une fois qu'une `Date` précise est passée. Pour définir un délai, passez un objet `Date` au paramètre `delayUntil` de la méthode `dispatch` :

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 24 heures
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

Si un Worker sort une tâche de sa file d'attente avant la date indiquée par son paramètre de délai, le pilote la replacera dans la file.

### Définir une priorité

Vos tâches peuvent être organisées en différents types/priorités de files d'attente en fonction de vos besoins. Par exemple, vous voudrez peut-être créer une file `email` et une file `background-processing` pour séparer vos tâches.

Commencez par étendre `QueueName` :

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Vous pouvez aussi définir un nombre de Workers par file lorsque vous instanciez un objet `QueueName` :

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

Définir `workerCount: 1` force cette file à traiter les tâches les unes à la suite des autres, ce qui sera utile pour des tâches dont l'ordre d'exécution est important.

Ensuite, indiquez le type de file à utiliser lors de la délégation (.emails) :

```swift
app.get("email") { req -> EventLoopFuture<String> inzz
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 24 heures
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// ou

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 24 heures
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

Lors d'un accès via l'objet `Application`, vous devriez avoir ceci :

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

Si vous ne précisez pas de file, la tâche sera envoyée dans la file `default`. Assurez-vous de suivre les instructions de la section **Premiers pas** pour démarrer les Workers pour chaque type de file.

## Planification de tâches

Le package Queues vous permet aussi de planifier des tâches devant s'exécuter à des moments précis.

!!! Avertissement
    Les tâches planifiées ne fonctionnent que si elles sont configurées avant le démarrage de l'application, comme dans `configure.swift`. Elles ne fonctionnent pas en réponse de routes.

### Démarrer le planificateur

Le planificateur a besoin d'un processus Worker dédié pour s'exécuter, semblable à un Worker de file. Vous pouvez lancer son Worker avec cette commande :

```sh
swift run App queues --scheduled
```

!!! Conseil
    Les Workers devraient toujours s'exécuter en continu sur l'environnement de production. Consultez votre hébergeur pour savoir combien de temps garder actif les processus à exécution longue. Heroku, par exemple, vous permet de marquer des instances comme "worker" comme ceci dans votre fichier Procfile : `worker: App queues --scheduled`.

### Créer un `ScheduledJob`

Pour commencer, créez un nouvel objet `ScheduledJob` ou `AsyncScheduledJob` :

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Ajoutez des services supplémentaire ici via injection de dépendances si vous en avez besoin.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Codez votre logique ici, vous pouvez éventuellement déléguer de nouvelles tâches à vos files.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Ajoutez des services supplémentaire ici via injection de dépendances si vous en avez besoin.

    func run(context: QueueContext) async throws {
        // Codez votre logique ici, vous pouvez éventuellement déléguer de nouvelles tâches à vos files.
    }
}
```

Puis, dans votre code de configuration, enregistrez votre tâche planifiée :

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

La tâche de l'exemple ci-dessus s'exécutera chaque année le 23 Mai à midi.

!!! Note
    Le planificateur hérite de la timezone de votre serveur.

### Méthodes de construction disponibles

Nous proposons deux styles d'API pour le planificateur :

- Construction par style calendaire, qui retournent des instances de constructeur permettant de chaîner les appels.
- Construction par style à intervales, qui exécutent les tâches à répétition à chaque durée fixée qui s'écoule.

### Construction calendaire

Vous devriez chaîner vos méthodes en construction par style calendaire jusqu'à ce que le compilateur ne vous affiche plus d'avertissement concernant un résultat inutilisé. Voici la liste des méthodes existantes :

| Méthode         | Modificateurs                                                | Description                                                                                                  |
|-----------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`                              | Le mois au cours duquel exécuter la tâche. Retourne un objet `Monthly` pour chaîner.                         |
| `monthly()`     | `on(_ day: Day) -> Daily`                                    | Le jour au cours duquel exécuter la tâche. Retourne un objet `Daily` pour chaîner.                           |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily`                            | Le jour de la semaine au cours duquel exécuter la tâche. Retourne un objet `Daily` pour chaîner.             |
| `daily()`       | `at(_ time: Time)`                                           | L'heure pile à laquelle exécuter la tâche. Cette méthode termine la chaîne.                                  |
|                 | `at(_ hour: Hour24, _ minute: Minute)`                       | Heure et minute auxquelles exécuter la tâche. Cette méthode termine la chaîne.                               |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | Heure et minute auxquelles exécuter la tâche, ainsi que la période (AM/PM). Cette méthode termine la chaîne. |
| `hourly()`      | `at(_ minute: Minute)`                                       | La minute à laquelle exécuter la tâche. Cette méthode termine la chaîne.                                     |
| `minutely()`    | `at(_ second: Second)`                                       | La seconde à laquelle exécuter la tâche. Cette méthode termine la chaîne.                                    |

### Construction par intervales (`.every(...)`)

Le planificateur permet aussi la planification par intervales fixes grâce aux méthodes `.every(...)` :

| Méthode               | Description                             |
|-----------------------|-----------------------------------------|
| `every(seconds: Int)` | Exécute la tâche toutes les X secondes. |
| `every(minutes: Int)` | Exécute la tâche toutes les X minutes.  |
| `every(hours: Int)`   | Exécute la tâche toutes les X heures.   |
| `every(days: Int)`    | Exécute la tâche tous les X jours.      |
| `every(weeks: Int)`   | Exécute la tâche toutes les X semaines. |

Exemple :

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### Raccourcis disponibles

Queues expose différentes énumérations pour simplifier la planification :

| Méthode         | Énumérations                          |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

Pour utiliser ces valeurs, appelez le modificateur approprié de votre méthode et passez-lui le cas d'énumération choisi. Par exemple :

```swift
// Chaque année en Janvier
.yearly().in(.january)

// Chaque premier jour du mois
.monthly().on(.first)

// Chaque semaine le dimanche
.weekly().on(.sunday)

// Tous les jours à minuit
.daily().at(.midnight)
```

## Délégation d'évènements

Le package Queues vous permet de définir des objets `JobEventDelegate` qui recevront des notifications lorsqu'un Worker agit sur une tâche. Cela peut vous servir pour monitorer, faire remonter des statistiques, ou émettre des alertes.

Pour commencer, conformez un objet à `JobEventDelegate` et implémentez les méthodes nécessaires :

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Appelée lorsqu'une tâche est déléguée à un Worker de file depuis une route.
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Appelée lorsqu'une tâche est placée dans la file de traitement et que son exécution commence.
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Appelée lorsque l'exécution d'une tâche est terminée et qu'elle a été enlevée de la file.
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Appelée lorsque l'exécution d'une tâche est terminée en erreur.
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

Puis, ajoutez-le à votre fichier de configuration :

```swift
app.queues.add(MyEventDelegate())
```

Il existe des packages tiers utilisant cette fonctionnalité de délégation pour fournir de la visibilité supplémentaire à vos Workers :

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Tester

Pour éviter les problèmes de synchronisation et permettre des tests déterministes, le package Queues fournit une librairie `XCTQueue` et un pilote `AsyncTestQueuesDriver` dédiés aux tests que vous pouvez utiliser comme ceci :

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Remplace le pilote utilisé pour les tests
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

Plus de détails sur cet [article du blog de Romain Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# Débogage

En utilisant [queues-redis-driver](https://github.com/vapor/queues-redis-driver) avec un serveur cluster compatible Redis, comme Redis ou Valkey sur Amazon AWS, vous pourriez rencontrer l'erreur suivante : `CROSSSLOT Keys in request don't hash to the same slot`.

Ceci n'arrive qu'en mode cluster, car Redis ou Valkey ne peuvent pas savoir sur quel noeud du cluster stoquer les données des tâches.

Pour corriger ce problème, ajoutez un [hash tag](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) aux noms des données de vos tâches en utilisant des accolades :

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
