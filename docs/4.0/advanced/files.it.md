# File

Vapor offre una semplice API per leggere e scrivere file in modo asincrono all'interno dei gestori di route. Questa API è costruita sopra il tipo [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) di NIO.

## Lettura

Il metodo principale per leggere un file consegna i chunk a un gestore di callback man mano che vengono letti dal disco. Il file da leggere è specificato dal suo percorso. I percorsi relativi cercheranno nella directory di lavoro corrente del processo.

```swift
// Legge un file dal disco in modo asincrono.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Oppure

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Lettura completata
```

Se si usano `EventLoopFuture`, il future restituito segnala quando la lettura è completata o si è verificato un errore. Se si usa `async`/`await`, una volta che `await` ritorna la lettura è completata. Se si è verificato un errore verrà lanciata un'eccezione.

### Stream

Il metodo `streamFile` converte un file in streaming in una `Response`. Questo metodo imposterà automaticamente gli header appropriati come `ETag` e `Content-Type`.

```swift
// Invia il file come risposta HTTP in streaming in modo asincrono.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Oppure

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

Il risultato può essere restituito direttamente dal tuo gestore di route.

### Collect

Il metodo `collectFile` legge il file specificato in un buffer.

```swift
// Legge il file in un buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in
    print(buffer) // ByteBuffer
}

// oppure

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning "Attenzione"
    Questo metodo richiede che l'intero file sia in memoria. Usa la lettura a chunk o in streaming per limitare l'uso della memoria.

## Scrittura

Il metodo `writeFile` supporta la scrittura di un buffer su un file.

```swift
// Scrive il buffer su un file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

Il future restituito segnala quando la scrittura è completata o si è verificato un errore.

## Middleware

Per ulteriori informazioni su come servire file dalla cartella _Public_ del tuo progetto automaticamente, vedi [Middleware &rarr; FileMiddleware](middleware.it.md#file-middleware).

## Avanzato

Per i casi che l'API di Vapor non supporta, puoi usare direttamente il tipo `NonBlockingFileIO` di NIO.

```swift
// Thread principale.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file",
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// In un gestore di route.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file",
    eventLoop: req.eventLoop)
print(fileHandle)
```

Per ulteriori informazioni, visita la [documentazione API](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) di SwiftNIO.
