# Kolejki

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) to napisany w czystym Swifcie system kolejkowania, który pozwala przenieść odpowiedzialność za zadania na osobnego workera.

Niektóre z zadań, do których ten pakiet dobrze się nadaje:

- Wysyłanie e-maili poza głównym wątkiem requestu
- Wykonywanie złożonych lub długotrwałych operacji na bazie danych
- Zapewnianie integralności i odporności zadań
- Przyspieszanie czasu odpowiedzi poprzez opóźnianie przetwarzania niekrytycznego
- Planowanie zadań do wykonania o określonym czasie

Ten pakiet jest podobny do [Ruby Sidekiq](https://github.com/mperham/sidekiq). Zapewnia następujące funkcje:

- Bezpieczną obsługę sygnałów `SIGTERM` i `SIGINT` wysyłanych przez dostawców hostingu w celu wskazania zamknięcia, restartu lub nowego wdrożenia.
- Różne priorytety kolejek. Na przykład możesz określić, że dane zadanie kolejki ma być uruchamiane na kolejce email, a inne zadanie na kolejce przetwarzania danych.
- Implementuje niezawodny proces kolejkowania, który pomaga radzić sobie z nieoczekiwanymi awariami.
- Zawiera funkcję `maxRetryCount`, która powtórzy zadanie aż do jego powodzenia, do określonej liczby prób.
- Wykorzystuje NIO, aby wykorzystać wszystkie dostępne rdzenie i EventLoopy do zadań.
- Pozwala użytkownikom planować zadania cykliczne

Queues posiada obecnie jeden oficjalnie wspierany driver, który komunikuje się z głównym protokołem:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues posiada również drivery tworzone przez społeczność:

- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/vapor-community/vapor-queues-fluent-driver)

!!! tip
    Nie powinieneś instalować pakietu `vapor/queues` bezpośrednio, chyba że tworzysz nowy driver. Zamiast tego zainstaluj jeden z pakietów driverów.

## Pierwsze kroki

Zobaczmy, jak zacząć korzystać z Queues.

### Pakiet

Pierwszym krokiem do korzystania z Queues jest dodanie jednego z driverów jako zależności do Twojego projektu w pliku manifestu SwiftPM. W tym przykładzie użyjemy drivera Redis.

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

Jeśli edytujesz manifest bezpośrednio w Xcode, automatycznie wykryje on zmiany i pobierze nową zależność po zapisaniu pliku. W przeciwnym razie z terminala uruchom `swift package resolve`, aby pobrać nową zależność.

### Konfiguracja

Kolejnym krokiem jest skonfigurowanie Queues w `configure.swift`. Jako przykład użyjemy biblioteki Redis:

```swift
import QueuesRedisDriver

try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Rejestrowanie `Job`a

Po zamodelowaniu zadania musisz dodać je do sekcji konfiguracji w następujący sposób:

```swift
// Register jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Uruchamianie workerów jako procesów

Aby uruchomić nowego workera kolejki, wykonaj `swift run App queues`. Możesz również wskazać konkretny typ workera do uruchomienia: `swift run App queues --queue emails`.

!!! tip
    Workery powinny działać nieprzerwanie w środowisku produkcyjnym. Skonsultuj się z Twoim dostawcą hostingu, aby dowiedzieć się, jak utrzymywać długo działające procesy przy życiu. Heroku, na przykład, pozwala określić dyna typu „worker” w ten sposób w pliku Procfile: `worker: Run queues`. Dzięki temu możesz uruchamiać workery z zakładki Dashboard/Resources lub za pomocą `heroku ps:scale worker=1` (lub dowolnej preferowanej liczby dynów).

### Uruchamianie workerów w tym samym procesie

Aby uruchomić workera w tym samym procesie co Twoja aplikacja (zamiast uruchamiać do tego celu całkowicie osobny serwer), wywołaj metody pomocnicze na `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

Aby uruchomić zaplanowane zadania w tym samym procesie, wywołaj następującą metodę:

```swift
try app.queues.startScheduledJobs()
```

!!! warning
    Jeśli nie uruchomisz workera kolejki ani z wiersza poleceń, ani jako workera działającego w tym samym procesie, zadania nie zostaną wysłane.

## Protokół `Job`

Zadania są definiowane za pomocą protokołu `Job` lub `AsyncJob`.

### Modelowanie obiektu `Job`:

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

Jeśli używasz `async`/`await`, powinieneś użyć `AsyncJob`:

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
    Upewnij się, że Twój typ `Payload` implementuje protokół `Codable`.

!!! tip
    Nie zapomnij postępować zgodnie z instrukcjami w sekcji **Pierwsze kroki**, aby dodać to zadanie do pliku konfiguracyjnego.

## Wysyłanie zadań

Aby wysłać zadanie do kolejki, potrzebujesz dostępu do instancji `Application` lub `Request`. Najczęściej będziesz wysyłać zadania wewnątrz handlera trasy:

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

Jeśli natomiast musisz wysłać zadanie z kontekstu, w którym obiekt `Request` nie jest dostępny (na przykład wewnątrz `Command`), musisz skorzystać z właściwości `queues` wewnątrz obiektu `Application`, na przykład tak:

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

### Ustawianie `maxRetryCount`

Zadania będą automatycznie ponawiane w przypadku błędu, jeśli określisz `maxRetryCount`. Na przykład:

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

### Określanie opóźnienia

Zadania mogą być również ustawione tak, aby uruchamiały się dopiero po upływie określonej `Date`. Aby określić opóźnienie, przekaż `Date` do parametru `delayUntil` w `dispatch`:

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

Jeśli zadanie zostanie pobrane z kolejki przed upływem parametru opóźnienia, zostanie ono ponownie umieszczone w kolejce przez driver.

### Określanie priorytetu

Zadania mogą być sortowane do różnych typów/priorytetów kolejek, w zależności od Twoich potrzeb. Możesz na przykład chcieć otworzyć kolejkę `email` oraz kolejkę `background-processing`, aby posortować zadania.

Zacznij od rozszerzenia `QueueName`:

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

Możesz również ustawić `workerCount` dla poszczególnej kolejki podczas tworzenia `QueueName`:

```swift
extension QueueName {
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
```

Ustawienie `workerCount: 1` sprawia, że dana kolejka przetwarza zadania kolejno, co jest przydatne, gdy kolejność zadań ma znaczenie.

Następnie określ typ kolejki podczas pobierania obiektu `jobs`:

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

Podczas dostępu z poziomu obiektu `Application` powinieneś postąpić następująco:

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

Jeśli nie określisz kolejki, zadanie zostanie uruchomione na kolejce `default`. Upewnij się, że postępujesz zgodnie z instrukcjami w sekcji **Pierwsze kroki**, aby uruchomić workery dla każdego typu kolejki.

## Planowanie zadań

Pakiet Queues pozwala również na planowanie zadań do wykonania w określonych momentach czasu.

!!! warning
    Zaplanowane zadania działają wyłącznie wtedy, gdy zostaną skonfigurowane przed uruchomieniem aplikacji, na przykład w `configure.swift`. Nie będą działać w handlerach tras.

### Uruchamianie workera schedulera

Scheduler wymaga uruchomienia osobnego procesu workera, podobnie jak worker kolejki. Możesz uruchomić workera, wykonując to polecenie:

```sh
swift run App queues --scheduled
```

!!! tip
    Workery powinny działać nieprzerwanie w środowisku produkcyjnym. Skonsultuj się z Twoim dostawcą hostingu, aby dowiedzieć się, jak utrzymywać długo działające procesy przy życiu. Heroku, na przykład, pozwala określić dyna typu „worker” w ten sposób w pliku Procfile: `worker: App queues --scheduled`

### Tworzenie `ScheduledJob`a

Na początek utwórz nowy `ScheduledJob` lub `AsyncScheduledJob`:

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

Następnie w kodzie konfiguracji zarejestruj zaplanowane zadanie:

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

Zadanie z powyższego przykładu będzie uruchamiane co roku, 23 maja o godzinie 12:00.

!!! tip
    Scheduler przyjmuje strefę czasową Twojego serwera.

### Dostępne metody buildera

Istnieją dwa style API schedulera:

- Buildery w stylu kalendarza, które zwracają obiekty buildera do dalszego łańcuchowania.
- Buildery w stylu interwałowym, które uruchamiają zadania co ustalony odstęp czasu.

Powinieneś kontynuować budowanie łańcucha schedulera w stylu kalendarza, dopóki kompilator nie przestanie ostrzegać o nieużywanym wyniku. Poniżej znajdują się wszystkie dostępne metody:

| Funkcja pomocnicza | Dostępne modyfikatory                   | Opis                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | Miesiąc, w którym zadanie ma zostać uruchomione. Zwraca obiekt `Monthly` do dalszego budowania.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | Dzień, w którym zadanie ma zostać uruchomione. Zwraca obiekt `Daily` do dalszego budowania.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | Dzień tygodnia, w którym zadanie ma zostać uruchomione. Zwraca obiekt `Daily`.               |
| `daily()`       | `at(_ time: Time)`                    | Godzina, o której zadanie ma zostać uruchomione. Ostatnia metoda w łańcuchu.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| Godzina i minuta, o której zadanie ma zostać uruchomione. Ostatnia metoda w łańcuchu.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | Godzina, minuta i okres, w którym zadanie ma zostać uruchomione. Ostatnia metoda w łańcuchu |
| `hourly()`      | `at(_ minute: Minute)`                 | Minuta, o której zadanie ma zostać uruchomione. Ostatnia metoda w łańcuchu.                      |
| `minutely()`    | `at(_ second: Second)`                 | Sekunda, o której zadanie ma zostać uruchomione. Ostatnia metoda w łańcuchu.                      |

### Metody buildera interwałowego (`.every(...)`)

Scheduler obsługuje również planowanie w stałych odstępach czasu za pomocą metod `.every(...)`:

| Funkcja pomocnicza | Opis                                                                    |
|-----------------|--------------------------------------------------------------------------------|
| `every(seconds: Int)` | Uruchamia zadanie co podaną liczbę sekund.                              |
| `every(minutes: Int)` | Uruchamia zadanie co podaną liczbę minut.                              |
| `every(hours: Int)`   | Uruchamia zadanie co podaną liczbę godzin.                                |
| `every(days: Int)`    | Uruchamia zadanie co podaną liczbę dni.                                 |
| `every(weeks: Int)`   | Uruchamia zadanie co podaną liczbę tygodni.                                |

Przykład:

```swift
app.queues.schedule(CleanupJob())
    .every(hours: 6)
```

### Dostępne pomocniki

Queues zawiera kilka pomocniczych enumów, które ułatwiają planowanie:

| Funkcja pomocnicza | Dostępny pomocniczy enum                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

Aby użyć pomocniczego enuma, wywołaj odpowiedni modyfikator na funkcji pomocniczej i przekaż wartość. Na przykład:

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

## Delegaci zdarzeń

Pakiet Queues pozwala określić obiekty `JobEventDelegate`, które będą otrzymywać powiadomienia, gdy worker podejmie działanie na zadaniu. Może to być wykorzystane do monitorowania, wyciągania wniosków lub celów związanych z alertowaniem.

Na początek dostosuj obiekt do protokołu `JobEventDelegate` i zaimplementuj wymagane metody

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

Następnie dodaj go w pliku konfiguracyjnym:

```swift
app.queues.add(MyEventDelegate())
```

Istnieje kilka pakietów firm trzecich, które wykorzystują funkcjonalność delegatów, aby dostarczyć dodatkowy wgląd w działanie Twoich workerów kolejki:

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)

## Testowanie

Aby uniknąć problemów z synchronizacją i zapewnić deterministyczne testowanie, pakiet Queues udostępnia bibliotekę `XCTQueue` oraz dedykowany do testów driver `AsyncTestQueuesDriver`, którego możesz użyć w następujący sposób:

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

Zobacz więcej szczegółów we [wpisie na blogu Romaina Pouclet](https://romain.codes/2024/10/08/using-and-testing-vapor-queues/).

# Rozwiązywanie problemów

Podczas korzystania z [queues-redis-driver](https://github.com/vapor/queues-redis-driver) z serwerem kompatybilnym z Redis działającym w trybie klastrowym, takim jak Redis lub Valkey na Amazon AWS, możesz napotkać ten komunikat błędu: `CROSSSLOT Keys in request don't hash to the same slot`.

Zdarza się to wyłącznie w trybie klastrowym, ponieważ Redis lub Valkey nie mogą mieć pewności, na którym węźle klastra przechowywać dane zadania.

Aby to naprawić, dodaj [hash tag](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags) do nazw wpisów danych Twoich zadań, używając nawiasów klamrowych w nazwach:

```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```
