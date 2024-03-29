# WebSocket

[WebSocket](https://it.wikipedia.org/wiki/WebSocket) è un protocollo di comunicazione bidirezionale usato per trasmettere messaggi tra client e server. A differenza di HTTP, che utilizza un pattern di richiesta-risposta, i WebSocket consentono di inviare un numero arbitrario di messaggi in entrambe le direzioni. L'API WebSocket di Vapor ti permette di creare sia client che server che gestiscono messaggi in modo asincrono.

## Server

Gli endpoint WebSocket possono essere aggiunti alla tua applicazione Vapor esistente utilizzando l'API di routing. Usa il metodo `webSocket` come faresti con `get` o `post`.

```swift
app.webSocket("echo") { req, ws in
    // WebSocket connesso.
    print(ws)
}
```

Le route WebSocket possono essere raggruppate e protette da middleware come le normali route.

Oltre ad accettare la richiesta HTTP in ingresso, i gestori WebSocket accettano la connessione WebSocket appena stabilita. Vedi sotto per ulteriori informazioni sull'utilizzo di questo WebSocket per inviare e leggere messaggi.

## Client

Per connetterti a un endpoint WebSocket remoto, usa `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // WebSocket connesso.
    print(ws)
}
```

Il metodo `connect` restituisce un future che si completa quando la connessione è stabilita. Una volta connesso, il blocco fornito verrà chiamato con il WebSocket appena connesso. Vedi sotto per ulteriori informazioni sull'utilizzo di questo WebSocket per inviare e leggere messaggi.

## Messaggi

La classe `WebSocket` ha metodi per inviare e ricevere messaggi e per ascoltare eventi come la chiusura. I WebSocket possono trasmettere dati tramite due protocolli: testo e binario. I messaggi di testo sono interpretati come stringhe UTF-8 mentre i dati binari sono interpretati come un array di byte.

### Invio

I messaggi possono essere inviati utilizzando il metodo `send` del WebSocket.

```swift
ws.send("Ciao, mondo")
```

Passare una `String` a questo metodo comporta l'invio di un messaggio di testo. I messaggi binari possono essere inviati passando un `[UInt8]`.

```swift
ws.send([1, 2, 3])
```

L'invio di messaggi è asincrono. Puoi fornire una `EventLoopPromise` al metodo di invio per essere notificato quando il messaggio è stato inviato o non è stato possibile inviarlo.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Riuscito o non riuscito a inviare.
}
```

Se stai usando `async`/`await` puoi usare `await` per attendere il completamento dell'operazione asincrona.

```swift
try await ws.send(...)
```

### Ricezione

I messaggi possono essere ricevuti utilizzando il metodo `onText` o `onBinary` del WebSocket.

```swift
ws.onText { ws, text in
    // Testo ricevuto.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] ricevuto.
    print(binary)
}
```

Per evitare la creazione di cicli di riferimento, il WebSocket stesso è passato come primo argomento al blocco di callback. Questo consente di accedere al WebSocket all'interno del blocco senza creare un riferimento circolare.

```swift
// Stampa il messagio ricevuto
ws.onText { ws, text in
    print(text)
}
```

## Chiusura

Per chiudere il WebSocket, chiamare il metodo `close`.

```swift
ws.close()
```

Questo metodo ritorna un futuro che si completa quando la connessione è stata chiusa. Come per l'invio di messaggi, puoi fornire una `EventLoopPromise` per essere notificato quando la connessione è stata chiusa.

```swift
ws.close(promise: nil)
```

Oppure puoi attendere la chiusura del WebSocket utilizzando `await`.

```swift
try await ws.close()
```

Per essere notificato quando il WebSocket è stato chiuso, puoi ascoltare l'evento `onClose`.

```swift
ws.onClose.whenComplete { result in
    // WebSocket chiuso.
}
```

La proprietà `closeCode` del WebSocket contiene il codice di chiusura inviato dal peer, e può essere utilizzato per determinare il motivo per cui la connessione è stata chiusa.

## Ping / Pong

Dei messaggi di ping e pong vengono inviati automaticamente dal client e dal server per mantenere attive le connessioni WebSocket. La tua applicazione può ascoltare questi eventi utilizzando i callback `onPing` e `onPong`.

```swift
ws.onPing { ws in 
    // Ping ricevuto.
}

ws.onPong { ws in
    // Pong ricevuto.
}
```
