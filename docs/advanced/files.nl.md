# Bestanden

Vapor biedt een eenvoudige API voor het asynchroon lezen en schrijven van bestanden binnen route handlers. Deze API is gebouwd op NIO's [`NonBlockingFileIO`](https://apple.github.io/swift-nio/docs/current/NIOPosix/Structs/NonBlockingFileIO.html) type.

## Lezen

De primaire methode voor het lezen van een bestand levert chunks aan een callback handler terwijl ze van de schijf worden gelezen. Het te lezen bestand wordt gespecificeerd door zijn pad. Relatieve paden zoeken in de huidige werkdirectory van het proces.

```swift
// Leest asynchroon een bestand van schijf.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Or

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Lezen is voltooid
```

Bij gebruik van `EventLoopFuture` zal de geretourneerde future signaleren wanneer het lezen voltooid is of dat er een fout is opgetreden. Als `async`/`await` gebruikt wordt, dan zal zodra de `await` teruggekeerd is, het lezen voltooid zijn. Als er een fout is opgetreden zal er een foutmelding worden gegeven.

### Stream

De `streamFile` methode converteert een streaming bestand naar een `Response`. Deze methode stelt automatisch de juiste headers in, zoals `ETag` en `Content-Type`.

```swift
// Streamt asynchroon bestand als HTTP antwoord.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Antwoord
}

// Of

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

Het resultaat kan direct door je route handler worden teruggegeven. 

### Collect 

De `collectFile` methode leest het opgegeven bestand in een buffer.

```swift
// Leest het bestand in een buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// of

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning "Waarschuwing"
    Deze methode vereist dat het hele bestand in één keer in het geheugen aanwezig is. Gebruik "chunked" of "streaming read" om het geheugengebruik te beperken.

## Schrijven

De `writeFile` methode ondersteunt het schrijven van een buffer naar een bestand.

```swift
// Schrijft buffer naar bestand.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

De geretourneerde future zal signaleren wanneer het schrijven voltooid is of dat er een fout is opgetreden.

## Middleware

Voor meer informatie over het automatisch serveren van bestanden uit de _Public_ map van je project, zie [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Geavanceerd

Voor gevallen die Vapor's API niet ondersteunt, kunt u NIO's `NonBlockingFileIO` type direct gebruiken. 

```swift
// Main thread.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// In een route handler.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

Ga voor meer informatie naar SwiftNIO's [API referentie](https://apple.github.io/swift-nio/docs/current/NIOPosix/Structs/NonBlockingFileIO.html).
