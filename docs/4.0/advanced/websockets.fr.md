# WebSockets

Les [WebSockets](https://en.wikipedia.org/wiki/WebSocket) permettent une communication bi-directionnelle entre client et server. A la différence de HTTP, qui suit un modèle requête/réponse, les partis communiquant via WebSocket peuvent envoyer un nombre de messages arbitraire dans l'une ou l'autre des directions. L'API WebSocket de Vapor vous permet de créer clients et serveurs capables de gérer des messages de façon asynchrone.

## Serveur

Vous pouvez ajouter des routes WebSocket à votre application Vapor via l'API Routing. Utilisez la méthode `webSocket` comme vous utiliseriez les méthodes `get` ou `post`. 

```swift
app.webSocket("echo") { req, ws in
    // WebSocket connectée.
    print(ws)
}
```

Les routes WebSocket peuvent être groupées et protégées par middleware comme des routes normales. 

En plus d'accepter des requêtes HTTP entrantes, les contrôleurs associés aux WebSockets reçoivent la connexion WebSocket nouvellement établie. Voir plus bas pour plus de détails sur l'utilisation de cette WebSocket pour envoyer et lire des messages.

## Client

Pour vous connecter à une route WebSocket distante, utilisez `WebSocket.connect`. 

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connecté à la WebSocket.
    print(ws)
}
```

La méthode `connect` retourne un futur qui s'accomplit une fois la connexion établie. Une fois connecté, la closure fournie sera appelée par la WebSocket nouvellement connectée. Voir plus bas pour plus de détails sur l'utilisation de cette WebSocket pour envoyer et lire des messages.

## Messages

La classe `WebSocket` possède des méthodes pour envoyer et recevoir des messages ainsi que pour écouter des évènements comme les closures. Les WebSockets peuvent transmettre des données selon deux protocoles : texte ou binaire. Les messages texte sont interprétés comme chaînes UTF-8, tandis que les données binaires sont interprétées comme un tableau d'octets.

### Envoi

Vous pouvez envoyer des messages grâce à la méthode `send` de l'objet WebSocket.

```swift
ws.send("Hello, world")
```

Envoyer un type `String` à cette méthode résultera en l'envoi d'un message de type texte. L'envoi de messages binaires se fait en passant un type `[UInt8]`. 

```swift
ws.send([1, 2, 3])
```

L'envoi de messages est asynchrone. Vous pouvez fournir un objet `EventLoopPromise` à la méthode send pour être notifié de la fin de l'envoi du message ou de son échec.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succès ou échec de l'envoi.
}
```

Si vous utilisez `async`/`await`, vous pouvez utiliserr `await` pour attendre la fin de l'opération asynchrone :

```swift
try await ws.send(...)
```

### Réception

Les messages entrants sont gérés par les callbacks `onText` et `onBinary`.

```swift
ws.onText { ws, text in
    // Type String reçu par cette WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // Type [UInt8] reçu par cette WebSocket.
    print(binary)
}
```

La WebSocket elle-même est passée en premier paramètre de ces callbacks pour éviter des références cycliques. Utilisez cette référence pour agir sur la WebSocket après réception de données. Par exemple, pour émettre une réponse :

```swift
// Renvoie le message reçu en écho.
ws.onText { ws, text in
    ws.send(text)
}
```

## Fermeture

Pour fermer une WebSocket, appelez la méthode `close`. 

```swift
ws.close()
```

Cette méthode retourne un futur qui s'accomplit une fois la WebSocket fermée. Comme `send`, vous pouvez aussi fournir une promesse à cette méthode.

```swift
ws.close(promise: nil)
```

Ou utiliser `await` si vous utilisez `async`/`await` :

```swift
try await ws.close()
```

Pour être notifié de la cloture de connexion par un des pairs connectés, utilisez `onClose`. Ce futur sera accompli dès lors que le client ou le serveur clot la WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Succès ou échec de la cloture de connexion.
}
```

La propriété `closeCode` est définie lorsque la WebSocket se ferme. Cela peut servir à connaitre la raison de fin de connexion.

## Ping / Pong

Des messages ping et pong sont envoyés automatiquement par le client et le serveur pour conserver les connexios WebSocket actives. Votre application peut écouter ces évènements grâce aux callbacks `onPing` et `onPong` :

```swift
ws.onPing { ws in 
    // Ping reçu.
}

ws.onPong { ws in
    // Pong reçu.
}
```
