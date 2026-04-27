# Servizi

`Application` e `Request` di Vapor sono progettati per essere estesi dalla tua applicazione e da package di terze parti. Le nuove funzionalità aggiunte a questi tipi vengono spesso chiamate servizi.

## Sola Lettura

Il tipo di servizio più semplice è quello in sola lettura. Questi servizi consistono di variabili calcolate o metodi aggiunti all'application o alla request.

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

I servizi in sola lettura possono dipendere da qualsiasi servizio preesistente, come `client` in questo esempio. Una volta aggiunta l'estensione, il tuo servizio personalizzato può essere usato come qualsiasi altra proprietà sulla request.

```swift
req.myAPI.foos()
```

## Modificabile

I servizi che necessitano di uno stato o di una configurazione possono utilizzare lo storage di `Application` e `Request` per memorizzare i dati. Supponiamo che tu voglia aggiungere la seguente struct `MyConfiguration` alla tua applicazione.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Per usare lo storage, devi dichiarare una `StorageKey`.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Questa è una struct vuota con un typealias `Value` che specifica quale tipo viene memorizzato. Usando un tipo vuoto come chiave, puoi controllare quale codice è in grado di accedere al tuo valore di storage. Se il tipo è internal o private, solo il tuo codice sarà in grado di modificare il valore associato nello storage.

Infine, aggiungi un'estensione ad `Application` per ottenere e impostare la struct `MyConfiguration`.

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

Una volta aggiunta l'estensione, puoi usare `myConfiguration` come una normale proprietà su `Application`.

```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Lifecycle

`Application` di Vapor ti consente di registrare gestori di lifecycle. Questi ti permettono di agganciarti a eventi come l'avvio e il shutdown.

```swift
// Stampa hello durante l'avvio.
struct Hello: LifecycleHandler {
    // Chiamato prima dell'avvio dell'applicazione.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Chiamato dopo l'avvio dell'applicazione.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Chiamato prima del shutdown dell'applicazione.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Aggiunge il gestore di lifecycle.
app.lifecycle.use(Hello())
```

## Lock

L'`Application` di Vapor include funzionalità per sincronizzare il codice usando i lock. Dichiarando una `LockKey`, puoi ottenere un lock unico e condiviso per sincronizzare l'accesso al tuo codice.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Esegui qualcosa.
}
```

Ogni chiamata a `lock(for:)` con la stessa `LockKey` restituirà lo stesso lock. Questo metodo è thread-safe.

Per un lock a livello di applicazione, puoi usare `app.sync`.

```swift
app.sync.withLock {
    // Esegui qualcosa.
}
```

## Request

I servizi destinati a essere usati nei gestori di route dovrebbero essere aggiunti a `Request`. I servizi di request dovrebbero usare il `Logger` e l'`EventLoop` della request. È importante che una request rimanga sullo stesso `EventLoop` o verrà lanciata un'asserzione quando la risposta viene restituita a Vapor.

Se un servizio deve lasciare l'`EventLoop` della request per svolgere del lavoro, dovrebbe assicurarsi di tornare all'`EventLoop` prima di terminare. Questo può essere fatto usando `hop(to:)` su `EventLoopFuture`.

I servizi di request che necessitano di accesso ai servizi dell'applicazione, come le configurazioni, possono usare `req.application`. Fai attenzione a considerare la thread-safety quando accedi all'applicazione da un gestore di route. In generale, solo le operazioni di lettura dovrebbero essere eseguite dalle request. Le operazioni di scrittura devono essere protette da lock.
