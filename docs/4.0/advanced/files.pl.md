# Pliki

Vapor oferuje prosty interfejs API do asynchronicznego odczytu i zapisu plików w handlerach tras. Ten interfejs API jest zbudowany na bazie typu [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) z NIO.

## Odczyt

Główna metoda do odczytu pliku dostarcza fragmenty (chunki) do handlera zwrotnego (callback) w miarę ich odczytywania z dysku. Plik do odczytu jest określany za pomocą jego ścieżki. Ścieżki względne będą szukane w bieżącym katalogu roboczym procesu.

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

Jeśli używane są `EventLoopFuture`, zwrócony future zasygnalizuje, gdy odczyt zostanie zakończony lub wystąpi błąd. Jeśli używane jest `async`/`await`, to po zwróceniu przez `await` odczyt jest zakończony. Jeśli wystąpił błąd, zostanie on rzucony.

### Strumień

Metoda `streamFile` konwertuje strumieniowany plik na `Response`. Ta metoda automatycznie ustawi odpowiednie nagłówki, takie jak `ETag` i `Content-Type`.

```swift
// Asynchronously streams file as HTTP response.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Or

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

Wynik może zostać zwrócony bezpośrednio przez twój handler trasy.

### Zbieranie

Metoda `collectFile` odczytuje wskazany plik do bufora.

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
    Ta metoda wymaga, aby cały plik znajdował się jednocześnie w pamięci. Użyj odczytu fragmentami (chunked) lub strumieniowego, aby ograniczyć zużycie pamięci.

## Zapis

Metoda `writeFile` obsługuje zapis bufora do pliku.

```swift
// Writes buffer to file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

Zwrócony future zasygnalizuje, gdy zapis zostanie zakończony lub wystąpi błąd.

## Middleware

Więcej informacji na temat automatycznego serwowania plików z folderu _Public_ twojego projektu znajdziesz w [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Zaawansowane

W przypadkach, których interfejs API Vapor nie obsługuje, możesz bezpośrednio użyć typu `NonBlockingFileIO` z NIO.

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

Więcej informacji znajdziesz w [dokumentacji API](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) SwiftNIO.
