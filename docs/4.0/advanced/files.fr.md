# Fichiers

Vapor offre une API simple pour la lecture et l'écriture asynchrone de fichiers dans les contrôleurs. Cette API est construite sur le type [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de NIO.

## Lecture

### Par extraits successifs

La principale méthode exposée pour la lecture de fichier envoie des extraits vers un callback au fur et à mesure de leur lecture sur le disque. Le fichier à lire est indiqué par son chemin. Les chemins relatifs chercheront dans le répertoire de travail courant du processus en cours.

```swift
// Lecture asynchrone d'un fichier sur le disque.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/chemin/vers/le/fichier") { chunk in
    print(chunk) // ByteBuffer
}

// Ou

try await req.fileio.readFile(at: "/chemin/vers/le/fichier") { chunk in
    print(chunk) // ByteBuffer
}
// Lecture terminée
```

Si vous utilisez des `EventLoopFuture`s, le futur retourné indiquera la fin de la lecture ou l'arrivée d'une erreur. Si vous utilisez `async`/`await`, alors la lecture sera terminée lorsque `await` aura fini son attente. En cas d'erreur, elle sera levée.

### Par diffusion de flux

La méthode `streamFile` convertit un flux de lecture de fichier en objet `Response`. Cette méthode ajoutera les entêtes appropriées comme `ETag` et `Content-Type` automatiquement.

```swift
// Diffuse de façon asynchrone un fichier en réponse HTTP.
req.fileio.streamFile(at: "/chemin/vers/le/fichier").map { res in
    print(res) // Response
}

// Ou

let res = req.fileio.streamFile(at: "/chemin/vers/le/fichier")
print(res)

```

Le résultat peut être retourné directement depuis votre contrôleur. 

### Par mise en mémoire 

La méthode `collectFile` lit le fichier indiqué et le stoque en mémoire.

```swift
// Place le contenu du fichier lu dans un buffer.
req.fileio.collectFile(at: "/chemin/vers/le/fichier").map { buffer in 
    print(buffer) // ByteBuffer
}

// ou

let buffer = req.fileio.collectFile(at: "/chemin/vers/le/fichier")
print(buffer)
```

!!! Attention
    Cette méthode nécessite le stoquage intégral du fichier en mémoire. Préférez une lecture en diffusion par flux ou en morcellement progressif pour limiter l'utilisation de la mémoire disponible.

## Écriture

La méthode `writeFile` permet d'écrire le contenu d'un buffer vers un fichier.

```swift
// Écrit un buffer vers un fichier.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/chemin/vers/le/fichier")
```

Le futur retourné indiquera la fin de l'écriture ou l'arrivée d'une erreur.

## Middleware

Pour plus d'informations relatives à l'exposition automatique des fichiers du dossier _Public_ de votre projet, voir [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Avancé

Pour les cas non supportés par les API de Vapor, vous pouvez utiliser le type `NonBlockingFileIO` de NIO directement. 

```swift
// Processus principal, accès depuis l'objet Application.
let fileHandle = try await app.fileio.openFile(
    path: "/chemin/vers/le/fichier", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// Dans un contrôleur, accès depuis l'objet Request.
let fileHandle = try await req.application.fileio.openFile(
    path: "/chemin/vers/le/fichier", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

Pour plus d'informations, veuillez lire la [documentation de l'API](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de SwiftNIO.
