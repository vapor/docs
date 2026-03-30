# Async

## Async Await

Swift 5.5 ha introdotto la concorrenza nel linguaggio sotto forma di `async`/`await`. Questo fornisce un modo di prima classe per gestire il codice asincrono nelle applicazioni Swift e Vapor.

Vapor è costruito utilizzando [SwiftNIO](https://github.com/apple/swift-nio.git), che fornisce tipi primitivi per la programmazione asincrona a basso livello. Questi tipi erano (e sono ancora) usati in tutto Vapor prima dell'arrivo di `async`/`await`. Tuttavia, la maggior parte del codice applicativo può ora essere scritto usando `async`/`await` invece di `EventLoopFuture`. Questo semplificherà il codice e lo renderà molto più facile da comprendere.

La maggior parte delle API di Vapor ora offre versioni sia per `EventLoopFuture` che per `async`/`await` tra cui scegliere. In generale, dovresti usare un solo modello di programmazione per route handler e non mischiarne più di uno nel tuo codice. Per le applicazioni che richiedono un controllo esplicito sugli event loop, o per applicazioni ad altissime prestazioni, si dovrebbero preferire gli `EventLoopFuture` finché non saranno implementati gli executor personalizzati. Per tutti gli altri, è preferibile utilizzare `async`/`await` poiché i benefici in termini di leggibilità e manutenibilità superano di gran lunga qualsiasi piccola penalità di prestazioni.

### Migrazione ad async/await

Ci sono alcuni passaggi necessari per migrare ad async/await. Per iniziare, se usi macOS devi avere macOS 12 Monterey o superiore e Xcode 13.1 o superiore. Per altre piattaforme devi eseguire Swift 5.5 o superiore. Poi, assicurati di aver aggiornato tutte le dipendenze.

Nel tuo `Package.swift`, imposta la versione degli strumenti a 5.5 in cima al file:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Poi, imposta la versione della piattaforma a macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Infine aggiorna il target `Run` per marcarlo come target eseguibile:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Nota: se stai effettuando il deploy su Linux assicurati di aggiornare anche la versione di Swift lì, ad esempio su Heroku o nel tuo Dockerfile. Per esempio il tuo Dockerfile cambierebbe in:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Ora puoi migrare il codice esistente. In generale le funzioni che restituiscono `EventLoopFuture` sono ora `async`. Per esempio:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Ora diventa:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Lavorare con le API vecchie e nuove

Se incontri API che non offrono ancora una versione `async`/`await`, puoi chiamare `.get()` su una funzione che restituisce un `EventLoopFuture` per convertirla.

Ad esempio:

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // usa futureResult
}
```

Può diventare:

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Se hai bisogno di fare il percorso inverso puoi convertire:

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

in:

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`

Potresti aver notato che alcune API in Vapor si aspettano o restituiscono un tipo generico `EventLoopFuture`. Se è la prima volta che senti parlare di futures, potrebbero sembrare un po' confusionari all'inizio. Non preoccuparti, questa guida ti mostrerà come sfruttare le loro potenti API.

`Promise` e `Future` sono tipi correlati ma distinti. Le promise vengono usate per _creare_ future. La maggior parte delle volte lavorerai con future restituite dalle API di Vapor e non avrai bisogno di preoccuparti di creare promise.

|Tipo|Descrizione|Mutabilità|
|-|-|-|
|`EventLoopFuture`|Riferimento a un valore che potrebbe non essere ancora disponibile.|Sola lettura|
|`EventLoopPromise`|Una promessa di fornire un valore in modo asincrono.|Lettura/Scrittura|

Le `Future` sono un'alternativa alle API asincrone basate su callback. Le future possono essere concatenate e trasformate in modi che le semplici closure non possono.

## Trasformazioni

Proprio come gli optional e gli array in Swift, le future possono essere mappate e flat-mappate. Queste sono le operazioni più comuni che eseguirai sulle future.

|Metodo|Argomento|Descrizione|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Mappa il valore di una future in un valore diverso.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Mappa il valore di una future in un valore diverso o in un errore.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Mappa il valore di una future in un _altro_ valore future.|
|[`transform`](#transform)|`U`|Mappa una future in un valore già disponibile.|

Se guardi le firme dei metodi `map` e `flatMap` su `Optional<T>` e `Array<T>`, vedrai che sono molto simili ai metodi disponibili su `EventLoopFuture<T>`.

### map

Il metodo `map` ti permette di trasformare il valore di una future in un altro valore. Poiché il valore della future potrebbe non essere ancora disponibile (potrebbe essere il risultato di un'operazione asincrona) dobbiamo fornire una closure per accettare il valore.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

/// Mappa la future string in un intero
let futureInt = futureString.map { string in
    print(string) // La String effettiva
    return Int(string) ?? 0
}

/// Ora abbiamo una future intera
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

Il metodo `flatMapThrowing` ti permette di trasformare il valore di una future in un altro valore _oppure_ lanciare un errore.

!!! info "Informazione"
    Poiché lanciare un errore deve creare internamente una nuova future, questo metodo ha il prefisso `flatMap` anche se la closure non accetta un ritorno di tipo future.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

/// Mappa la future string in un intero
let futureInt = futureString.flatMapThrowing { string in
    print(string) // La String effettiva
    // Converte la string in un intero o lancia un errore
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// Ora abbiamo una future intera
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

Il metodo `flatMap` ti permette di trasformare il valore di una future in un altro valore future. Il nome "flat" map deriva dal fatto che è ciò che ti permette di evitare la creazione di future annidate (ad esempio `EventLoopFuture<EventLoopFuture<T>>`). In altre parole, ti aiuta a mantenere piatti i valori.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

/// Supponiamo di aver creato un client HTTP
let client: Client = ...

/// flatMap della future string in una future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// Ora abbiamo una future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info "Informazione"
    Se invece avessimo usato `map` nell'esempio precedente, avremmo ottenuto: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

Per chiamare un metodo che lancia eccezioni all'interno di un `flatMap`, usa le parole chiave `do` / `catch` di Swift e crea una [future completata](#makefuture).

```swift
/// Supponiamo future string e client dall'esempio precedente.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Un metodo sincrono che lancia eccezioni.
        url = try convertToURL(string)
    } catch {
        // Usa l'event loop per creare una future pre-completata.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```

### transform

Il metodo `transform` ti permette di modificare il valore di una future, ignorando il valore esistente. Questo è particolarmente utile per trasformare i risultati di `EventLoopFuture<Void>` dove il valore effettivo della future non è importante.

!!! tip "Suggerimento"
    `EventLoopFuture<Void>`, a volte chiamata segnale, è una future il cui unico scopo è notificarti del completamento o del fallimento di qualche operazione asincrona.

```swift
/// Supponiamo di ottenere una future void da qualche API
let userDidSave: EventLoopFuture<Void> = ...

/// Trasforma la future void in uno stato HTTP
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```

Anche se abbiamo fornito un valore già disponibile a `transform`, questa è comunque una _trasformazione_. La future non si completerà finché tutte le future precedenti non si saranno completate (o fallite).

### Concatenazione

La cosa ottima delle trasformazioni sulle future è che possono essere concatenate. Questo ti permette di esprimere molte conversioni e sottoattività facilmente.

Modifichiamo gli esempi precedenti per vedere come possiamo sfruttare la concatenazione.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

/// Supponiamo di aver creato un client HTTP
let client: Client = ...

/// Trasforma la string in un URL, poi in una response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

Dopo la chiamata iniziale a map, viene creata una `EventLoopFuture<URL>` temporanea. Questa future viene poi immediatamente flat-mappata in una `EventLoopFuture<Response>`.

## Future

Diamo un'occhiata ad alcuni altri metodi per utilizzare `EventLoopFuture<T>`.

### makeFuture

Puoi usare un event loop per creare una future pre-completata con un valore o un errore.

```swift
// Crea una future pre-completata con successo.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Crea una future pre-completata con fallimento.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

Puoi usare `whenComplete` per aggiungere una callback che verrà eseguita quando la future ha successo o fallisce.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // La String effettiva
    case .failure(let error):
        print(error) // Un Swift Error
    }
}
```

!!! note "Nota"
    Puoi aggiungere quante callback vuoi a una future.

### Get

Nel caso in cui non esista un'alternativa basata sulla concorrenza per un'API, puoi attendere il valore della future usando `try await future.get()`.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

/// Attendi che la string sia pronta
let string: String = try await futureString.get()
print(string) /// String
```

### Wait

!!! warning "Attenzione"
    La funzione `wait()` è obsoleta, vedi [`Get`](#get) per l'approccio raccomandato.

Puoi usare `.wait()` per attendere in modo sincrono che la future sia completata. Poiché una future potrebbe fallire, questa chiamata lancia eccezioni.

```swift
/// Supponiamo di ottenere una future string da qualche API
let futureString: EventLoopFuture<String> = ...

/// Blocca finché la string non è pronta
let string = try futureString.wait()
print(string) /// String
```

`wait()` può essere usato solo su un thread in background o sul thread principale, cioè in `configure.swift`. _Non_ può essere usato su un thread dell'event loop, cioè nelle closure delle route.

!!! warning "Attenzione"
    Il tentativo di chiamare `wait()` su un thread dell'event loop causerà un assertion failure.

## Promise

La maggior parte delle volte trasformerai future restituite da chiamate alle API di Vapor. Tuttavia, a un certo punto potresti aver bisogno di creare una tua promise.

Per creare una promise, avrai bisogno di accedere a un `EventLoop`. Puoi accedere a un event loop da `Application` o `Request` a seconda del contesto.

```swift
let eventLoop: EventLoop

// Crea una nuova promise per una string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completa la future associata.
promiseString.succeed("Hello")

// Fa fallire la future associata.
promiseString.fail(...)
```

!!! info "Informazione"
    Una promise può essere completata solo una volta. Qualsiasi completamento successivo verrà ignorato.

Le promise possono essere completate (`succeed` / `fail`) da qualsiasi thread. Per questo le promise richiedono un event loop per essere inizializzate. Le promise assicurano che l'azione di completamento venga restituita al suo event loop per l'esecuzione.

## Event Loop

Quando la tua applicazione si avvia, di solito creerà un event loop per ogni core nella CPU su cui è in esecuzione. Ogni event loop ha esattamente un thread. Se hai familiarità con gli event loop di Node.js, quelli in Vapor sono simili. La differenza principale è che Vapor può eseguire più event loop in un singolo processo poiché Swift supporta il multi-threading.

Ogni volta che un client si connette al tuo server, verrà assegnato a uno degli event loop. Da quel momento in poi, tutta la comunicazione tra il server e quel client avverrà su quello stesso event loop (e, per associazione, sul thread di quell'event loop).

L'event loop è responsabile del monitoraggio dello stato di ogni client connesso. Se c'è una richiesta dal client in attesa di essere letta, l'event loop attiva una notifica di lettura, causando la lettura dei dati. Una volta letta l'intera richiesta, tutte le future in attesa dei dati di quella richiesta saranno completate.

Nelle closure delle route, puoi accedere all'event loop corrente tramite `Request`.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning "Attenzione"
    Vapor si aspetta che le closure delle route rimangano su `req.eventLoop`. Se cambi thread, devi assicurarti che l'accesso a `Request` e la future della risposta finale avvengano sull'event loop della richiesta.

Al di fuori delle closure delle route, puoi ottenere uno degli event loop disponibili tramite `Application`.

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

Puoi cambiare l'event loop di una future usando `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

Chiamare codice bloccante su un thread dell'event loop può impedire alla tua applicazione di rispondere alle richieste in arrivo in modo tempestivo. Un esempio di chiamata bloccante sarebbe qualcosa come `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Mette il thread dell'event loop in pausa.
    sleep(5)

    /// Restituisce una semplice stringa una volta che il thread si risveglia.
    return "Hello, world!"
}
```

`sleep(_:)` è un comando che blocca il thread corrente per il numero di secondi specificato. Se esegui lavoro bloccante come questo direttamente su un event loop, l'event loop non sarà in grado di rispondere a nessun altro client assegnato ad esso per la durata del lavoro bloccante. In altre parole, se fai `sleep(5)` su un event loop, tutti gli altri client connessi a quell'event loop (possibilmente centinaia o migliaia) subiranno un ritardo di almeno 5 secondi.

Assicurati di eseguire qualsiasi lavoro bloccante in background. Usa le promise per notificare l'event loop quando questo lavoro è completato in modo non bloccante.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Spedisce del lavoro da eseguire su un thread in background
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Mette il thread in background in pausa
        /// Questo non influenzerà nessuno degli event loop
        sleep(5)

        /// Quando il "lavoro bloccante" è completato,
        /// restituisce il risultato.
        return "Hello world!"
    }
}
```

Non tutte le chiamate bloccanti saranno ovvie come `sleep(_:)`. Se sospetti che una chiamata che stai usando possa essere bloccante, ricerca il metodo stesso o chiedi a qualcuno. Le sezioni sottostanti spiegano più in dettaglio come i metodi possono bloccarsi.

### I/O Bound

Il blocking I/O bound significa attendere una risorsa lenta come una rete o un disco rigido che può essere ordini di grandezza più lenta della CPU. Bloccare la CPU mentre si attendono queste risorse porta a spreco di tempo.

!!! danger "Pericolo"
    Non effettuare mai chiamate bloccanti I/O bound direttamente su un event loop.

Tutti i package di Vapor sono costruiti su SwiftNIO e usano I/O non bloccante. Ci sono molti package Swift e librerie C che usano I/O bloccante. È probabile che se una funzione sta eseguendo I/O su disco o rete e usa un'API sincrona (senza callback o future) sia bloccante.

### CPU Bound

La maggior parte del tempo durante una richiesta viene trascorso ad attendere risorse esterne come query al database e richieste di rete da caricare. Poiché Vapor e SwiftNIO sono non bloccanti, questo tempo morto può essere usato per rispondere ad altre richieste in arrivo. Tuttavia, alcune route nella tua applicazione potrebbero dover eseguire lavoro pesante legato alla CPU come risultato di una richiesta.

Mentre un event loop sta elaborando lavoro legato alla CPU, non sarà in grado di rispondere ad altre richieste in arrivo. Questo è normalmente accettabile poiché le CPU sono veloci e la maggior parte del lavoro CPU che le applicazioni web eseguono è leggero. Ma questo può diventare un problema se le route con lavoro CPU a lunga esecuzione impediscono alle richieste verso route più veloci di essere risposte rapidamente.

Identificare il lavoro CPU a lunga esecuzione nella tua app e spostarlo su thread in background può aiutare a migliorare l'affidabilità e la reattività del tuo servizio. La differenza tra lavoro I/O bound e CPU bound non è sempre chiara, e alla fine spetta a te determinare dove vuoi tracciare il confine.

Un esempio comune di lavoro CPU pesante è l'hashing Bcrypt durante la registrazione e il login degli utenti. Bcrypt è deliberatamente molto lento e intensivo per la CPU per ragioni di sicurezza. Questo potrebbe essere il lavoro CPU più intensivo che una semplice applicazione web esegue effettivamente. Spostare l'hashing su un thread in background può permettere alla CPU di intercalare il lavoro dell'event loop durante il calcolo degli hash, il che porta a una maggiore concorrenza.
