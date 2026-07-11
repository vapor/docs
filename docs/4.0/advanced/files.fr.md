# Fichiers

Vapor propose une API simple pour lire et écrire des fichiers de façon asynchrone dans les gestionnaires de requêtes. Cette API est construite au-dessus du type [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de NIO.

## Lecture

La méthode principale pour lire un fichier délivre des morceaux de données (chunks) à un gestionnaire de rappel (callback) au fur et à mesure de leur lecture depuis le disque. Le fichier à lire est spécifié par son chemin. Les chemins relatifs seront recherchés dans le répertoire de travail courant du processus.

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

Si vous utilisez des `EventLoopFuture`s, le futur retourné signalera quand la lecture sera terminée ou qu'une erreur sera survenue. Si vous utilisez `async`/`await`, alors une fois que le `await` a retourné, la lecture est terminée. Si une erreur est survenue, elle sera levée.

### Flux (Stream)

La méthode `streamFile` convertit un flux de fichier en `Response`. Cette méthode définit automatiquement les en-têtes appropriés tels que `ETag` et `Content-Type`.

```swift
// Asynchronously streams file as HTTP response.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Or

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

Le résultat peut être retourné directement par votre gestionnaire de requête.

### Collecte

La méthode `collectFile` lit le fichier spécifié dans un buffer.

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
    Cette méthode nécessite que le fichier entier soit en mémoire en une seule fois. Utilisez une lecture découpée en morceaux ou en flux pour limiter l'utilisation de la mémoire.

## Écriture

La méthode `writeFile` permet d'écrire un buffer dans un fichier.

```swift
// Writes buffer to file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

Le futur retourné signalera quand l'écriture sera terminée ou qu'une erreur sera survenue.

## Middleware

Pour plus d'informations sur la mise à disposition automatique des fichiers du dossier _Public_ de votre projet, consultez [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Avancé

Pour les cas que l'API de Vapor ne prend pas en charge, vous pouvez utiliser directement le type `NonBlockingFileIO` de NIO.

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

Pour plus d'informations, consultez la [référence de l'API](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de SwiftNIO.
