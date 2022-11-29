# Queues

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) is een puur Swift wachtrijsysteem waarmee je taakverantwoordelijkheid kunt overdragen aan een side worker. 

Sommige van de taken waar dit pakket goed voor werkt:

- E-mails versturen buiten de main request thread
- Het uitvoeren van complexe of langlopende database operaties 
- Zorgen voor integriteit en bestendigheid van het werk 
- Snellere reactietijd door uitstel van niet-kritieke bewerkingen
- Taken plannen om op een specifiek tijdstip te gebeuren

Dit pakket is vergelijkbaar met [Ruby Sidekiq](https://github.com/mperham/sidekiq). Het biedt de volgende mogelijkheden aan:

- Veilig omgaan met `SIGTERM` en `SIGINT` signalen die door hosting providers worden gestuurd om een shutdown, herstart, of nieuwe deploy aan te geven.
- Verschillende wachtrijprioriteiten. U kunt bijvoorbeeld een wachtrijtaak opgeven die op de e-mailwachtrij moet worden uitgevoerd en een andere taak die op de gegevensverwerkingswachtrij moet worden uitgevoerd.
- Implementeert het betrouwbare wachtrijproces om te helpen bij onverwachte storingen.
- Bevat een `maxRetryCount` functie die de opdracht zal herhalen totdat deze slaagt tot een gespecificeerd aantal.
- Gebruikt NIO om alle beschikbare cores te gebruiken en EventLoops voor taken.
- Hiermee kunnen gebruikers herhalende taken plannen

Queues heeft momenteel één officieel ondersteund stuurprogramma dat een interface heeft met het hoofdprotocol:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues heeft ook community-based drivers:
- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/m-barthelemy/vapor-queues-fluent-driver)

!!! tip
    U moet het `vapor/queues` pakket niet direct installeren, tenzij u een nieuw stuurprogramma bouwt. Installeer in plaats daarvan een van de stuurprogrammapakketten. 

## Aan De Slag

Laten we eens kijken hoe je aan de slag kunt met wachtrijen.

### Package

De eerste stap om Queues te gebruiken is het toevoegen van een van de stuurprogramma's als een afhankelijkheid van je project in je SwiftPM package manifest bestand. In dit voorbeeld gebruiken we het Redis stuurprogramma. 

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Alle andere afhankelijkheden ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Als u het manifest direct in Xcode bewerkt, zal het automatisch de wijzigingen oppikken en de nieuwe dependency ophalen wanneer het bestand wordt opgeslagen. Anders, voer `swift package resolve` uit vanuit Terminal om de nieuwe dependency op te halen.

### Configuratie

De volgende stap is het configureren van wachtrijen in `configure.swift`. We gebruiken de Redis bibliotheek als voorbeeld:

```swift
try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Registreren van een `Job`

Na het modelleren van een job moet u deze toevoegen aan uw configuratiesectie zoals dit:

```swift
//Registreer jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Workers Uitvoeren Als Processen

Om een nieuwe wachtrijwerker te starten, voer `vapor run queues` uit. U kunt ook een specifiek type werker specificeren om te draaien: `vapor run queues --queue emails`.

!!! tip
    Workers moeten blijven draaien in productie. Raadpleeg uw hosting provider om uit te vinden hoe u langlopende processen in leven kunt houden. Heroku, bijvoorbeeld, staat je toe om "worker" dyno's te specificeren zoals dit in je Procfile: `worker: Run queues`. Met dit in plaats, kun je workers starten op het Dashboard/Resources tab, of met `heroku ps:scale worker=1` (of elk gewenst aantal dynos).

### Lopende Workers in uitvoering

Om een worker te draaien in hetzelfde proces als je applicatie (in tegenstelling tot het starten van een hele aparte server om het af te handelen), roep de convenience methodes op in `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

Om geplande taken in proces uit te voeren, roept u de volgende methode op:

```swift
try app.queues.startScheduledJobs()
```

!!! warning "Waarschuwing"
    Als je de wachtrij-werker niet start, hetzij via de opdrachtregel, hetzij via de in-proces-werker, zullen de jobs niet worden verzonden. 

## Het `Job` Protocol

Jobs worden gedefinieerd door het `Job` of `AsyncJob` protocol.

### Het modelleren van een `Job` object:

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
        // Dit is waar je de e-mail zou sturen
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // Als u geen fouten wilt afhandelen, kunt u gewoon een toekomst teruggeven. U kunt deze functie ook helemaal weglaten. 
        return context.eventLoop.future()
    }
}
```

Als je `async`/`await` gebruikt moet je `AsyncJob` gebruiken:

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // Dit is waar je de e-mail zou sturen
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // Als u geen fouten wilt afhandelen, kunt u gewoon terugkeren. Je kunt deze functie ook helemaal weglaten. 
    }
}
```

!!! info
    Zorg ervoor dat uw `Payload` type het `Codable` protocol implementeert.
!!! tip
    Vergeet niet de instructies in **Aan De Slag** te volgen om deze taak aan uw configuratiebestand toe te voegen. 

## Jobs Dispatchen

Om een wachtrijjob te dispatchen, heb je toegang nodig tot een instantie van `Application` of `Request`. Je zult waarschijnlijk jobs versturen binnen een route handler:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// of

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

Als u in plaats daarvan een opdracht moet verzenden vanuit een context waar het `Request` object niet beschikbaar is (zoals bijvoorbeeld vanuit een `Command`), dan moet u de `queues` eigenschap binnen het `Application` object gebruiken, zoals bijvoorbeeld:

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

### Instelling `maxRetryCount`

Jobs zullen zichzelf automatisch opnieuw proberen bij een fout als je een `maxRetryCount` opgeeft. Bijvoorbeeld: 

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

// of

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### Een Vertraging Opgeven

Jobs kunnen ook zo worden ingesteld dat ze pas worden uitgevoerd als een bepaalde `Datum` is verstreken. Om een vertraging op te geven, geef je een `Datum` op in de `delayUntil` parameter in `dispatch`:

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 1 dag
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

Als een opdracht vóór de vertragingsparameter wordt verwijderd, wordt de opdracht door de bestuurder opnieuw geplaatst. 

### Geef Een Prioriteit Aan 

Jobs kunnen gesorteerd worden in verschillende wachtrij types/prioriteiten afhankelijk van uw behoeften. U kunt bijvoorbeeld een `email` wachtrij en een `background-processing` wachtrij openen om taken te sorteren. 

Begin met `QueueName` uit te breiden:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Dan, specificeer het wachtrij type wanneer je het `jobs` object ophaalt:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 1 dag
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// of

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 1 dag
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

Bij het benaderen vanuit het `Application` object moet je als volgt te werk gaan:

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

Als u geen wachtrij opgeeft, wordt de taak uitgevoerd op de `standaard` wachtrij. Zorg ervoor dat u de instructies in **Aan De Slag** volgt om werkers voor elk wachtrijtype te starten. 

## Jobs Inplannen

Met het pakket Queues kunt u ook taken plannen die op bepaalde tijdstippen moeten worden uitgevoerd.

### De planner starten
De scheduler vereist dat een afzonderlijk workerproces draait, gelijkaardig aan de queue worker. U kunt de worker starten door dit commando uit te voeren: 

```sh
swift run Run queues --scheduled
```

!!! tip
    Workers moeten blijven draaien in productie. Raadpleeg uw hosting provider om uit te vinden hoe u langlopende processen in leven kunt houden. Heroku, bijvoorbeeld, staat je toe om "worker" dyno's te specificeren zoals dit in je Procfile: `worker: Run queues --scheduled`

### Een `ScheduledJob` Maken

Om te beginnen, maak je een nieuwe `ScheduledJob` of `AsyncScheduledJob`:

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Voeg hier extra diensten toe via dependency injection, als je die nodig hebt.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Doe wat werk hier, misschien een andere job.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Voeg hier extra diensten toe via dependency injection, als je die nodig hebt.

    func run(context: QueueContext) async throws {
        // Doe wat werk hier, misschien een andere job.
    }
}
```

Registreer vervolgens in uw configureercode de geplande job: 

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

De opdracht in het bovenstaande voorbeeld wordt elk jaar uitgevoerd op 23 mei om 12:00 PM.

!!! tip
    De Scheduler neemt de tijdzone van uw server.

### Beschikbare bouwmethodes
Er zijn vijf hoofdmethoden die aangeroepen kunnen worden op een scheduler, die elk hun eigen builder object maken dat meer helper methoden bevat. U moet doorgaan met het bouwen van een scheduler-object totdat de compiler u geen waarschuwing geeft over een ongebruikt resultaat. Zie hieronder voor alle beschikbare methoden:

| Helper Functie  | Beschikbare Modifiers                 | Beschrijving                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | De maand om de job in uit te voeren. Geeft een `Maand` object voor verdere opbouw.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | De dag om de job uit te voeren. Geeft een `Daily` object voor verdere opbouw.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | De dag van de week om de job op uit te voeren. Geeft als resultaat een `Daily` object.               |
| `daily()`       | `at(_ time: Time)`                    | De tijd om de opdracht uit te voeren. Laatste methode in de keten.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| Het uur en de minuten om de job uit te voeren. Laatste methode in de keten.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | Het uur, de minuten en de periode om de job uit te voeren. Eindmethode van de keten |
| `hourly()`      | `at(_ minute: Minute)`                 | De minuut om de opdracht uit te voeren. De laatste methode van de ketting.                      |

### Beschikbare helpers 
Wachtrijen worden geleverd met enkele helpers enums om het plannen te vergemakkelijken: 

| Helper Functie | Beschikbare Helper Enum                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

Om de helper-enum te gebruiken, roep de juiste modifier aan op de helperfunctie en geef de waarde door. Bijvoorbeeld:

```swift
// Elk jaar in januari 
.yearly().in(.january)

// Elke maand op de eerste dag 
.monthly().on(.first)

// Elke week op zondag 
.weekly().on(.sunday)

// Elke dag om middernacht
.daily().at(.midnight)
```

## Event Delegates 
Het Queues pakket maakt het mogelijk om `JobEventDelegate` objecten te specificeren die notificaties zullen ontvangen wanneer de werker actie onderneemt op een job. Dit kan gebruikt worden voor monitoring, inzichten te verschaffen, of waarschuwingsdoeleinden. 

Om te beginnen, conformeer een object aan `JobEventDelegate` en implementeer alle vereiste methodes

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Wordt aangeroepen wanneer de taak wordt verzonden naar de wachtrijwerker vanuit een route
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Wordt aangeroepen wanneer de taak in de verwerkingswachtrij wordt geplaatst en het werk begint
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Wordt aangeroepen wanneer de taak klaar is met verwerken en verwijderd is uit de wachtrij
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Wordt aangeroepen wanneer de opdracht klaar is met verwerken maar een fout had
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

Voeg het dan toe in uw configuratiebestand:

```swift
app.queues.add(MyEventDelegate())
```

Er zijn een aantal pakketten van derden die de delegate-functionaliteit gebruiken om extra inzicht te verschaffen in uw wachtrijwerkers:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)