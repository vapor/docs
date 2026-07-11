# Dateien

Vapor bietet eine einfache API zum asynchronen Lesen und Schreiben von Dateien innerhalb von Route-Handlern. Diese API baut auf NIOs [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio)-Typ auf.

## Lesen

Die Hauptmethode zum Lesen einer Datei liefert Chunks an einen Callback-Handler, sobald diese von der Festplatte gelesen werden. Die zu lesende Datei wird durch ihren Pfad angegeben. Bei relativen Pfaden wird im aktuellen Arbeitsverzeichnis des Prozesses gesucht.

```swift
// Asynchronously reads a file from disk.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Or

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Read is complete
```

Wenn `EventLoopFuture`s verwendet werden, signalisiert das zurückgegebene Future, wann das Lesen abgeschlossen wurde oder ein Fehler aufgetreten ist. Wenn `async`/`await` verwendet wird, ist das Lesen abgeschlossen, sobald `await` zurückgekehrt ist. Ist ein Fehler aufgetreten, wird dieser geworfen.

### Stream

Die Methode `streamFile` konvertiert eine Datei, die gestreamt wird, in eine `Response`. Diese Methode setzt automatisch passende Header wie `ETag` und `Content-Type`.

```swift
// Asynchronously streams file as HTTP response.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Or

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

Das Ergebnis kann direkt von deinem Route-Handler zurückgegeben werden.

### Collect

Die Methode `collectFile` liest die angegebene Datei in einen Buffer ein.

```swift
// Reads the file into a buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// or

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning
    Diese Methode erfordert, dass die gesamte Datei auf einmal im Speicher vorliegt. Verwende chunk-weises oder gestreamtes Lesen, um den Speicherverbrauch zu begrenzen.

## Schreiben

Die Methode `writeFile` unterstützt das Schreiben eines Buffers in eine Datei.

```swift
// Writes buffer to file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

Das zurückgegebene Future signalisiert, wann das Schreiben abgeschlossen wurde oder ein Fehler aufgetreten ist.

## Middleware

Weitere Informationen zum automatischen Ausliefern von Dateien aus dem _Public_-Ordner deines Projekts findest du unter [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Fortgeschritten

Für Fälle, die von Vapors API nicht unterstützt werden, kannst du NIOs `NonBlockingFileIO`-Typ direkt verwenden.

```swift
// Main thread.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// In a route handler.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

Weitere Informationen findest du in SwiftNIOs [API-Referenz](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio).
