# WebSockets

Les [WebSockets](https://en.wikipedia.org/wiki/WebSocket) permettent une communication bidirectionnelle entre un client et un serveur. Contrairement à HTTP, qui suit un schéma requête-réponse, les pairs WebSocket peuvent envoyer un nombre arbitraire de messages dans les deux sens. L'API WebSocket de Vapor vous permet de créer à la fois des clients et des serveurs qui gèrent les messages de manière asynchrone.

## Serveur

Des points de terminaison WebSocket peuvent être ajoutés à votre application Vapor existante en utilisant l'API de routage. Utilisez la méthode `webSocket` comme vous utiliseriez `get` ou `post`.

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

Les routes WebSocket peuvent être groupées et protégées par des middlewares comme des routes normales.

En plus d'accepter la requête HTTP entrante, les gestionnaires WebSocket acceptent la connexion WebSocket nouvellement établie. Voir ci-dessous pour plus d'informations sur l'utilisation de ce WebSocket pour envoyer et lire des messages.

## Client

Pour vous connecter à un point de terminaison WebSocket distant, utilisez `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

La méthode `connect` retourne un futur qui se termine lorsque la connexion est établie. Une fois connectée, la Closure fournie sera appelée avec le WebSocket nouvellement connecté. Voir ci-dessous pour plus d'informations sur l'utilisation de ce WebSocket pour envoyer et lire des messages.

## Messages

La classe `WebSocket` dispose de méthodes pour envoyer et recevoir des messages, ainsi que pour écouter des événements comme la fermeture de la connexion. Les WebSockets peuvent transmettre des données via deux protocoles : texte et binaire. Les messages texte sont interprétés comme des chaînes UTF-8, tandis que les données binaires sont interprétées comme un tableau d'octets.

### Envoi

Les messages peuvent être envoyés en utilisant la méthode `send` du WebSocket.

```swift
ws.send("Hello, world")
```

Passer un `String` à cette méthode entraîne l'envoi d'un message texte. Des messages binaires peuvent être envoyés en passant un `[UInt8]`.

```swift
ws.send([1, 2, 3])
```

L'envoi de messages est asynchrone. Vous pouvez fournir un `EventLoopPromise` à la méthode `send` pour être notifié lorsque le message a fini d'être envoyé ou a échoué à l'envoi.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succeeded or failed to send.
}
```

Si vous utilisez `async`/`await`, vous pouvez utiliser `await` pour attendre la fin de l'opération asynchrone.

```swift
try await ws.send(...)
```

### Réception

Les messages entrants sont gérés via les callbacks `onText` et `onBinary`.

```swift
ws.onText { ws, text in
    // String received by this WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] received by this WebSocket.
    print(binary)
}
```

Le WebSocket lui-même est fourni comme premier paramètre de ces callbacks afin d'éviter les cycles de référence. Utilisez cette référence pour agir sur le WebSocket après avoir reçu des données. Par exemple, pour envoyer une réponse :

```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## Fermeture

Pour fermer un WebSocket, appelez la méthode `close`.

```swift
ws.close()
```

Cette méthode retourne un futur qui se terminera lorsque le WebSocket aura été fermé. Comme pour `send`, vous pouvez également passer une promesse à cette méthode.

```swift
ws.close(promise: nil)
```

Ou utilisez `await` si vous utilisez `async`/`await` :

```swift
try await ws.close()
```

Pour être notifié lorsque le pair ferme la connexion, utilisez `onClose`. Ce futur se terminera lorsque le client ou le serveur fermera le WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Succeeded or failed to close.
}
```

La propriété `closeCode` est définie lorsque le WebSocket se ferme. Elle peut être utilisée pour déterminer pourquoi le pair a fermé la connexion.

## Ping / Pong

Les messages ping et pong sont envoyés automatiquement par le client et le serveur pour maintenir les connexions WebSocket actives. Votre application peut écouter ces événements en utilisant les callbacks `onPing` et `onPong`.

```swift
ws.onPing { ws in 
    // Ping was received.
}

ws.onPong { ws in
    // Pong was received.
}
```
