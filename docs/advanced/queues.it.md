# Code

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) è un sistema di code che ti permette di delegare la responsabilità dei task a un worker separato. Ciò significa che puoi eseguire operazioni di lunga durata o complesse senza bloccare il thread principale della tua applicazione, migliorando così i tempi di risposta e la scalabilità.

Alcuni dei task per cui questo package funziona bene:

- Invio di email al di fuori del thread della request principale;
- Esecuzione di operazioni di database complesse o di lunga durata;
- Garanzia di integrità e resilienza dei job;
- Velocizzare i tempi di risposta ritardando l'elaborazione non critica;
- Pianificazione di job da eseguire in un momento specifico.

Questo package è simile a [Ruby Sidekiq](https://github.com/mperham/sidekiq). Fornisce le seguenti funzionalità:

- Gestione sicura dei segnali `SIGTERM` e `SIGINT` inviati dai provider di hosting per indicare uno shutdown, un riavvio o un nuovo deploy;
- Diverse priorità di coda. Ad esempio, puoi specificare che un job venga eseguito sulla coda email e un altro sulla coda di elaborazione dati;
- Implementa il processo di coda affidabile per gestire i guasti imprevisti;
- Include una funzionalità `maxRetryCount` che ripeterà il job finché non termina con successo, fino a un conteggio specificato;
- Usa NIO per sfruttare tutti i core e gli `EventLoop` disponibili per i job;
- Consente agli utenti di pianificare task ripetitivi.

Attualmente c'è un driver Redis ufficiale per Queues:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

E ci sono anche alcuni driver di terze parti:

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip "Suggerimento"
    A meno che tu non stia costruendo un nuovo driver, non dovresti installare il package `vapor/queues` direttamente. Installa invece uno dei package driver sopra elencati, che includono `vapor/queues` come dipendenza.

## Per Iniziare

Vediamo come puoi iniziare a usare Queues.

### Package

Il primo passo è aggiungere uno dei driver come dipendenza al tuo progetto nel file manifest del package SwiftPM. In questo esempio, useremo il driver Redis.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Qualsiasi altra dipendenza ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            // Altre dipendenze
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

Se modifichi il manifest direttamente in Xcode, rileverà automaticamente le modifiche e recupererà la nuova dipendenza quando il file viene salvato. Altrimenti, dal Terminale, esegui `swift package resolve` per recuperare la nuova dipendenza.

### Configurazione

Il passo successivo è configurare Queues in `configure.swift`. Useremo la libreria Redis come esempio:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Registrare un `Job`

Dopo aver modellato un job devi aggiungerlo alla sezione di configurazione in questo modo:

```swift
// Registra i job
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Eseguire Worker come Processi

Per avviare un nuovo worker di coda, esegui `swift run App queues`. Puoi anche specificare un tipo specifico di worker da eseguire: `swift run App queues --queue emails`.

!!! tip "Suggerimento"
    I worker dovrebbero rimanere in esecuzione in produzione. Consulta il tuo provider di hosting per scoprire come mantenere in vita i processi a lungo termine. Heroku, ad esempio, ti consente di specificare dyno "worker" in questo modo nel tuo Procfile: `worker: Run queues`. Con questo in atto, puoi avviare worker dalla scheda Dashboard/Resources, o con `heroku ps:scale worker=1` (o qualsiasi numero di dyno preferito).

### Eseguire Worker in-process

Per eseguire un worker nello stesso processo della tua applicazione (al contrario di avviare un server separato per gestirlo), chiama i metodi di convenienza su `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

Per eseguire job pianificati in-process, chiama il seguente metodo:

```swift
try app.queues.startScheduledJobs()
```

!!! warning "Attenzione"
    Se non avvii il worker di coda tramite riga di comando o il worker in-process, i job non verranno inviati.

## Il Protocollo `Job`

I job sono definiti dal protocollo `Job` o `AsyncJob`.

### Modellare un oggetto `Job`:

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
        // Qui è dove invieresti l'email
        return context.eventLoop.future()
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // Se non vuoi gestire gli errori puoi semplicemente restituire un future. Puoi anche omettere completamente questa funzione.
        return context.eventLoop.future()
    }
}
```

Se usi `async`/`await` dovresti usare `AsyncJob`:

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email

    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // Qui è dove invieresti l'email
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // Se non vuoi gestire gli errori puoi semplicemente tornare. Puoi anche omettere completamente questa funzione.
    }
}
```

!!! info "Informazione"
    Assicurati che il tipo `Payload` implementi il protocollo `Codable`.

!!! tip "Suggerimento"
    Non dimenticare di aggiungere questo job alla configurazione come descritto nella sezione **Per Iniziare**, altrimenti non sarà disponibile per l'invio.

## Inviare Job

Per inviare un job di coda, hai bisogno di un'istanza di `Application` o `Request`. Molto probabilmente invierai job all'interno di un gestore di route:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// oppure

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

Se invece hai bisogno di inviare un job da un contesto in cui l'oggetto `Request` non è disponibile (ad esempio, dall'interno di un `Command`), dovrai usare la proprietà `queues` all'interno dell'oggetto `Application`, come:

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

### Impostare `maxRetryCount`

I job si ritenteranno automaticamente in caso di errore se specifichi un `maxRetryCount`. Ad esempio:

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

// oppure

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### Specificare un ritardo

I job possono anche essere impostati per essere eseguiti solo dopo che una certa data è passata. Per specificare un ritardo, passa una `Date` nel parametro `delayUntil` in `dispatch`:

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Un giorno
    try await req.queue.dispatch(
        EmailJob.self,
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

Se un job viene rimosso dalla coda prima del suo parametro di ritardo, il job verrà rimesso in coda dal driver.

### Specificare una priorità

I job possono essere ordinati in diversi tipi/priorità di coda in base alle tue esigenze. Ad esempio, potresti voler aprire una coda `email` e una coda `background-processing` per ordinare i job.

Inizia estendendo `QueueName`:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Puoi anche impostare un `workerCount` per coda quando crei un `QueueName`:

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

Impostare `workerCount: 1` fa sì che quella coda elabori i job consecutivamente, il che è utile quando l'ordine dei job è importante.

Poi, specifica il tipo di coda quando recuperi l'oggetto `jobs`:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Un giorno
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self,
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// oppure

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // Un giorno
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

Quando accedi dall'oggetto `Application` dovresti procedere come segue:

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

Se non specifichi una coda, il job verrà eseguito sulla coda `default`. Assicurati di seguire le istruzioni in **Per Iniziare** per avviare worker per ogni tipo di coda.

## Pianificazione dei Job

Il package Queues ti consente anche di pianificare job da eseguire in certi momenti.

!!! warning "Attenzione"
    I job pianificati funzionano solo se impostati prima che l'applicazione si avvii, ad esempio in `configure.swift`. Non funzioneranno nei gestori di route.

### Avviare il worker dello scheduler

Lo scheduler richiede un processo worker separato in esecuzione, simile al worker di coda. Puoi avviare il worker eseguendo questo comando:

```sh
swift run App queues --scheduled
```

!!! tip "Suggerimento"
    I worker dovrebbero rimanere in esecuzione in produzione. Consulta il tuo provider di hosting per scoprire come mantenere in vita i processi a lunga esecuzione. Heroku, ad esempio, ti consente di specificare dyno "worker" in questo modo nel tuo Procfile: `worker: App queues --scheduled`

### Creare un `ScheduledJob`

Per iniziare, crea un nuovo `ScheduledJob` o `AsyncScheduledJob`:

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // Aggiungi qui servizi extra tramite dependency injection, se ne hai bisogno.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Esegui del lavoro qui, magari metti in coda un altro job.
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // Aggiungi qui servizi extra tramite dependency injection, se ne hai bisogno.

    func run(context: QueueContext) async throws {
        // Esegui del lavoro qui, magari metti in coda un altro job.
    }
}
```

Poi, nel tuo codice di configurazione, registra il job pianificato:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

Il job nell'esempio sopra verrà eseguito ogni anno il 23 maggio alle 12:00.

!!! tip "Suggerimento"
    Lo Scheduler utilizza il fuso orario del tuo server.

### Metodi builder disponibili

Ci sono due stili di API scheduler:

- Builder in stile calendario che restituiscono oggetti builder per il concatenamento.
- Builder in stile intervallo che eseguono job ogni durata fissa.

Dovresti continuare a costruire una catena di scheduler in stile calendario finché il compilatore non ti dà un avviso su un risultato inutilizzato. Vedi di seguito tutti i metodi disponibili:

| Funzione Helper | Modificatori Disponibili                   | Descrizione                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | Il mese in cui eseguire il job. Restituisce un oggetto `Monthly` per ulteriore costruzione.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | Il giorno in cui eseguire il job. Restituisce un oggetto `Daily` per ulteriore costruzione.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | Il giorno della settimana in cui eseguire il job. Restituisce un oggetto `Daily`.               |
| `daily()`       | `at(_ time: Time)`                    | L'ora in cui eseguire il job. Metodo finale della catena.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| L'ora e il minuto in cui eseguire il job. Metodo finale della catena.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | L'ora, il minuto e il periodo in cui eseguire il job. Metodo finale della catena. |
| `hourly()`      | `at(_ minute: Minute)`                 | Il minuto in cui eseguire il job. Metodo finale della catena.                      |
| `minutely()`    | `at(_ second: Second)`                 | Il secondo in cui eseguire il job. Metodo finale della catena.                      |

### Metodi builder a intervallo (`.every(...)`)

Lo scheduler supporta anche la pianificazione a intervallo fisso con i metodi `.every(...)`:

| Funzione Helper | Descrizione                                                                    |
|-----------------|--------------------------------------------------------------------------------|
| `every(seconds: Int)` | Esegue il job ogni dato numero di secondi.                              |
| `every(minutes: Int)` | Esegue il job ogni dato numero di minuti.                              |
| `every(hours: Int)`   | Esegue il job ogni dato numero di ore.                                |
| `every(days: Int)`    | Esegue il job ogni dato numero di giorni.                                 |
| `every(weeks: Int)`   | Esegue il job ogni dato numero di settimane.                                |

Esempio:

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### Helper disponibili

Queues include alcuni enum helper per rendere più semplice la pianificazione:

| Funzione Helper | Enum Helper Disponibili                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

Per usare l'enum helper, chiama il modificatore appropriato sulla funzione helper e passa il valore. Ad esempio:

```swift
// Ogni anno a gennaio
.yearly().in(.january)

// Ogni mese il primo giorno
.monthly().on(.first)

// Ogni settimana di domenica
.weekly().on(.sunday)

// Ogni giorno a mezzanotte
.daily().at(.midnight)
```

## Delegate degli Eventi

Il package Queues ti consente di specificare oggetti `JobEventDelegate` che riceveranno notifiche quando il worker esegue un'azione su un job. Questo può essere usato per il monitoraggio, la raccolta di informazioni o scopi di allerta.

Per iniziare, conforma un oggetto a `JobEventDelegate` e implementa i metodi richiesti

```swift
struct MyEventDelegate: JobEventDelegate {
    /// Chiamato quando il job viene inviato al worker di coda da una route
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Chiamato quando il job viene inserito nella coda di elaborazione e inizia il lavoro
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Chiamato quando il job ha terminato l'elaborazione ed è stato rimosso dalla coda
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// Chiamato quando il job ha terminato l'elaborazione ma ha avuto un errore
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

Poi, aggiungilo nel tuo file di configurazione:

```swift
app.queues.add(MyEventDelegate())
```

Ci sono alcuni package di terze parti che usano la funzionalità delegate per fornire ulteriori informazioni sui tuoi worker di coda:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Testing

Per evitare problemi di sincronizzazione e garantire test deterministici, il package Queues fornisce una libreria `XCTQueue` e un driver `AsyncTestQueuesDriver` dedicato ai test che puoi usare come segue:

```swift
final class UserCreationServiceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)

        // Sovrascrive il driver usato per i test
        app.queues.use(.asyncTest)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
}
```

Vedi maggiori dettagli nel [post del blog di Romain Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# Risoluzione dei Problemi

Quando si usa [queues-redis-driver](https://github.com/vapor/queues-redis-driver) con un server compatibile Redis basato su cluster, come Redis o Valkey su Amazon AWS, potresti incontrare questo messaggio di errore: `CROSSSLOT Keys in request don't hash to the same slot`.

Questo accade solo in modalità cluster, perché Redis o Valkey non possono sapere con certezza su quale nodo del cluster archiviare i dati del job.

Per risolvere questo, aggiungi un [hash tag](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) ai nomi delle voci dei dati del tuo job usando parentesi graffe nei nomi:

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
