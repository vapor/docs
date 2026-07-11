# Queues

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) ist ein reines Swift-Warteschlangensystem, mit dem du die Verantwortung für Aufgaben an einen separaten Worker auslagern kannst.

Einige Aufgaben, für die sich dieses Paket gut eignet:

- Versenden von E-Mails außerhalb des Haupt-Request-Threads
- Ausführen komplexer oder lang laufender Datenbankoperationen
- Sicherstellen der Integrität und Ausfallsicherheit von Jobs
- Beschleunigen der Antwortzeit durch Verzögern nicht kritischer Verarbeitung
- Planen von Jobs, die zu einem bestimmten Zeitpunkt ausgeführt werden sollen

Dieses Paket ist [Ruby Sidekiq](https://github.com/mperham/sidekiq) ähnlich. Es bietet die folgenden Funktionen:

- Sicherer Umgang mit `SIGTERM`- und `SIGINT`-Signalen, die von Hosting-Anbietern gesendet werden, um ein Herunterfahren, einen Neustart oder ein neues Deployment anzuzeigen.
- Unterschiedliche Queue-Prioritäten. Du kannst beispielsweise festlegen, dass ein Queue-Job auf der E-Mail-Queue und ein anderer Job auf der Datenverarbeitungs-Queue ausgeführt wird.
- Implementiert den zuverlässigen Queue-Prozess, um bei unerwarteten Fehlern zu helfen.
- Enthält eine `maxRetryCount`-Funktion, die den Job bis zu einer festgelegten Anzahl wiederholt, bis er erfolgreich ist.
- Nutzt NIO, um alle verfügbaren Kerne und EventLoops für Jobs zu verwenden.
- Ermöglicht es Nutzern, wiederkehrende Aufgaben zu planen

Queues verfügt derzeit über einen offiziell unterstützten Treiber, der mit dem Hauptprotokoll kommuniziert:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues verfügt außerdem über community-basierte Treiber:

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip
    Du solltest das Paket `vapor/queues` nicht direkt installieren, es sei denn, du entwickelst einen neuen Treiber. Installiere stattdessen eines der Treiberpakete.

## Erste Schritte

Schauen wir uns an, wie du mit Queues loslegen kannst.

### Package

Der erste Schritt zur Nutzung von Queues besteht darin, einen der Treiber als Abhängigkeit in der SwiftPM-Package-Manifestdatei deines Projekts hinzuzufügen. In diesem Beispiel verwenden wir den Redis-Treiber.

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

Wenn du das Manifest direkt in Xcode bearbeitest, werden die Änderungen automatisch übernommen und die neue Abhängigkeit beim Speichern der Datei abgerufen. Andernfalls führe im Terminal `swift package resolve` aus, um die neue Abhängigkeit abzurufen.

### Konfiguration

Der nächste Schritt besteht darin, Queues in `configure.swift` zu konfigurieren. Als Beispiel verwenden wir die Redis-Bibliothek:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Einen `Job` registrieren

Nachdem du einen Job modelliert hast, musst du ihn wie folgt zu deinem Konfigurationsabschnitt hinzufügen:

```swift
// Register jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Worker als Prozesse ausführen

Um einen neuen Queue-Worker zu starten, führe `swift run App queues` aus. Du kannst auch einen bestimmten Worker-Typ angeben: `swift run App queues --queue emails`.

!!! tip
    Worker sollten in der Produktion durchgehend laufen. Erkundige dich bei deinem Hosting-Anbieter, wie du lang laufende Prozesse am Leben erhalten kannst. Heroku erlaubt es dir beispielsweise, "worker"-Dynos in deinem Procfile wie folgt anzugeben: `worker: Run queues`. Damit kannst du Worker über den Reiter Dashboard/Resources starten, oder mit `heroku ps:scale worker=1` (oder einer beliebigen bevorzugten Anzahl an Dynos).

### Worker im gleichen Prozess ausführen

Um einen Worker im gleichen Prozess wie deine Anwendung auszuführen (statt einen komplett separaten Server dafür zu starten), rufe die Hilfsmethoden auf `Application` auf:

```swift
try app.queues.startInProcessJobs(on: .default)
```

Um geplante Jobs im gleichen Prozess auszuführen, rufe die folgende Methode auf:

```swift
try app.queues.startScheduledJobs()
```

!!! warning
    Wenn du den Queue-Worker weder über die Kommandozeile noch als In-Process-Worker startest, werden die Jobs nicht ausgeführt.

## Das `Job`-Protokoll

Jobs werden durch das `Job`- oder `AsyncJob`-Protokoll definiert.

### Ein `Job`-Objekt modellieren:

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

Bei Verwendung von `async`/`await` solltest du `AsyncJob` verwenden:

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
    Stelle sicher, dass dein `Payload`-Typ das `Codable`-Protokoll implementiert.

!!! tip
    Vergiss nicht, die Anweisungen unter **Erste Schritte** zu befolgen, um diesen Job zu deiner Konfigurationsdatei hinzuzufügen.

## Jobs verteilen

Um einen Queue-Job zu verteilen (dispatch), benötigst du Zugriff auf eine Instanz von `Application` oder `Request`. Höchstwahrscheinlich wirst du Jobs innerhalb eines Route-Handlers verteilen:

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

Wenn du stattdessen einen Job aus einem Kontext heraus verteilen musst, in dem das `Request`-Objekt nicht verfügbar ist (wie zum Beispiel innerhalb eines `Command`), musst du die `queues`-Eigenschaft des `Application`-Objekts verwenden, etwa so:

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

### `maxRetryCount` festlegen

Jobs werden bei einem Fehler automatisch erneut ausgeführt, wenn du `maxRetryCount` angibst. Zum Beispiel:

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

### Eine Verzögerung angeben

Jobs können auch so eingestellt werden, dass sie erst nach Ablauf eines bestimmten `Date` ausgeführt werden. Um eine Verzögerung anzugeben, übergib ein `Date` an den Parameter `delayUntil` in `dispatch`:

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

Wenn ein Job vor Ablauf seines Verzögerungsparameters aus der Queue geholt wird, wird der Job vom Treiber erneut in die Queue eingereiht.

### Eine Priorität angeben

Jobs können je nach Bedarf in verschiedene Queue-Typen/Prioritäten einsortiert werden. Zum Beispiel möchtest du vielleicht eine `email`-Queue und eine `background-processing`-Queue eröffnen, um Jobs zu sortieren.

Beginne damit, `QueueName` zu erweitern:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Du kannst beim Erstellen eines `QueueName` auch eine `workerCount` pro Queue festlegen:

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

Das Festlegen von `workerCount: 1` sorgt dafür, dass diese Queue Jobs nacheinander verarbeitet, was nützlich ist, wenn die Reihenfolge der Jobs wichtig ist.

Gib dann beim Abrufen des `jobs`-Objekts den Queue-Typ an:

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

Beim Zugriff innerhalb des `Application`-Objekts solltest du wie folgt vorgehen:

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

Wenn du keine Queue angibst, wird der Job auf der `default`-Queue ausgeführt. Achte darauf, die Anweisungen unter **Erste Schritte** zu befolgen, um Worker für jeden Queue-Typ zu starten.

## Jobs planen

Das Queues-Paket ermöglicht es dir außerdem, Jobs so zu planen, dass sie zu bestimmten Zeitpunkten ausgeführt werden.

!!! warning
    Geplante Jobs funktionieren nur, wenn sie eingerichtet werden, bevor die Anwendung hochfährt, etwa in `configure.swift`. In Route-Handlern funktionieren sie nicht.

### Den Scheduler-Worker starten

Der Scheduler benötigt einen separaten laufenden Worker-Prozess, ähnlich wie der Queue-Worker. Du kannst den Worker mit folgendem Befehl starten:

```sh
swift run App queues --scheduled
```

!!! tip
    Worker sollten in der Produktion durchgehend laufen. Erkundige dich bei deinem Hosting-Anbieter, wie du lang laufende Prozesse am Leben erhalten kannst. Heroku erlaubt es dir beispielsweise, "worker"-Dynos in deinem Procfile wie folgt anzugeben: `worker: App queues --scheduled`

### Einen `ScheduledJob` erstellen

Beginne damit, einen neuen `ScheduledJob` oder `AsyncScheduledJob` zu erstellen:

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

Registriere den geplanten Job anschließend in deinem Konfigurationscode:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

Der Job im obigen Beispiel wird jedes Jahr am 23. Mai um 12:00 Uhr ausgeführt.

!!! tip
    Der Scheduler übernimmt die Zeitzone deines Servers.

### Verfügbare Builder-Methoden

Es gibt zwei Arten von Scheduler-APIs:

- Kalenderartige Builder, die zum Verketten Builder-Objekte zurückgeben.
- Intervallartige Builder, die Jobs in einem festen Zeitabstand ausführen.

Du solltest die kalenderartige Scheduler-Kette so lange weiter aufbauen, bis der Compiler dich nicht mehr vor einem ungenutzten Ergebnis warnt. Nachfolgend findest du alle verfügbaren Methoden:

| Hilfsfunktion | Verfügbare Modifikatoren               | Beschreibung                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | Der Monat, in dem der Job ausgeführt werden soll. Gibt ein `Monthly`-Objekt für weiteren Aufbau zurück.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | Der Tag, an dem der Job ausgeführt werden soll. Gibt ein `Daily`-Objekt zurück.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | Der Wochentag, an dem der Job ausgeführt werden soll. Gibt ein `Daily`-Objekt zurück.               |
| `daily()`       | `at(_ time: Time)`                    | Die Uhrzeit, zu der der Job ausgeführt werden soll. Letzte Methode in der Kette.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| Die Stunde und Minute, zu der der Job ausgeführt werden soll. Letzte Methode in der Kette.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | Die Stunde, Minute und Tagesperiode, zu der der Job ausgeführt werden soll. Letzte Methode der Kette |
| `hourly()`      | `at(_ minute: Minute)`                 | Die Minute, zu der der Job ausgeführt werden soll. Letzte Methode der Kette.                      |
| `minutely()`    | `at(_ second: Second)`                 | Die Sekunde, zu der der Job ausgeführt werden soll. Letzte Methode der Kette.                      |

### Intervall-Builder-Methoden (`.every(...)`)

Der Scheduler unterstützt außerdem die Planung in festen Intervallen mit `.every(...)`-Methoden:

| Hilfsfunktion | Beschreibung                                                                    |
|-----------------|--------------------------------------------------------------------------------|
| `every(seconds: Int)` | Führt den Job alle angegebenen Sekunden aus.                              |
| `every(minutes: Int)` | Führt den Job alle angegebenen Minuten aus.                              |
| `every(hours: Int)`   | Führt den Job alle angegebenen Stunden aus.                                |
| `every(days: Int)`    | Führt den Job alle angegebenen Tage aus.                                 |
| `every(weeks: Int)`   | Führt den Job alle angegebenen Wochen aus.                                |

Beispiel:

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### Verfügbare Helfer

Queues wird mit einigen Hilfs-Enums ausgeliefert, die die Planung erleichtern:

| Hilfsfunktion | Verfügbares Hilfs-Enum                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

Um das Hilfs-Enum zu verwenden, rufe den entsprechenden Modifikator auf der Hilfsfunktion auf und übergib den Wert. Zum Beispiel:

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

## Event-Delegates

Das Queues-Paket ermöglicht es dir, `JobEventDelegate`-Objekte anzugeben, die Benachrichtigungen erhalten, wenn der Worker eine Aktion an einem Job durchführt. Dies kann für Monitoring, das Aufzeigen von Erkenntnissen oder Benachrichtigungszwecke verwendet werden.

Um loszulegen, lasse ein Objekt dem Protokoll `JobEventDelegate` entsprechen und implementiere alle erforderlichen Methoden

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

Füge es anschließend in deiner Konfigurationsdatei hinzu:

```swift
app.queues.add(MyEventDelegate())
```

Es gibt eine Reihe von Drittanbieter-Paketen, die die Delegate-Funktionalität nutzen, um zusätzliche Einblicke in deine Queue-Worker zu bieten:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Testen

Um Synchronisationsprobleme zu vermeiden und deterministisches Testen sicherzustellen, stellt das Queues-Paket eine `XCTQueue`-Bibliothek sowie einen speziell für Tests vorgesehenen Treiber `AsyncTestQueuesDriver` bereit, die du wie folgt verwenden kannst:

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

Weitere Details findest du in [Romain Pouclets Blogbeitrag](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# Fehlerbehebung

Bei der Verwendung von [queues-redis-driver](https://github.com/vapor/queues-redis-driver) mit einem clusterbasierten, Redis-kompatiblen Server, wie zum Beispiel Redis oder Valkey auf Amazon AWS, kann folgende Fehlermeldung auftreten: `CROSSSLOT Keys in request don't hash to the same slot`.

Dies tritt nur im Cluster-Modus auf, da Redis oder Valkey nicht mit Sicherheit wissen können, auf welchem Cluster-Knoten die Job-Daten gespeichert werden sollen.

Um dies zu beheben, füge mithilfe geschweifter Klammern einen [Hash-Tag](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) zu den Namen deiner Job-Dateneinträge hinzu:

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
