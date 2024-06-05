# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket) ermöglichen eine bidirektionale Kommunikation zwischen einem Client und einem Server. Im Gegensatz zu HTTP, das auf dem Anfrage-Antwort-Prinzip basiert, können WebSocket-Peers - also sozusagen Kommunikationsendpunkte - eine beliebige Anzahl von Nachrichten in beide Richtungen senden. Mit Vapor kannst du sowohl Clients als auch Server erstellen und Nachrichten asynchron verarbeiten lassen.
## Server

WebSocket-Endpunkte können mithilfe der Routing-API zu einer bestehenden Vapor-Anwendung hinzugefügt werden. Hierzu verwenden wir die `webSocket`-Methode ähnlich wie `get` oder `post`.

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

WebSocket-Endpunkte können, wie gewöhnliche Endpunkte, ebenfalls durch eine Middleware gruppiert und geschützt werden.

WebSocket-Handler akzeptieren nicht nur die eingehende HTTP-Request, sondern auch die neu eingerichtete WebSocket-Verbindung. Weitere Informationen zur Verwendung dieses WebSockets zum Senden und Lesen von Nachrichten findest du weiter unten.
## Client

Um eine solche Verbindung zu einem entfernen WebSocket-Endpunkt herzustellen, benutzen wir `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

Die Methode `connect` gibt einen Future zurück, der abgeschlossen wird, sobald die Verbindung hergestellt ist. Mit Bestehen der Verbindung, wird der bereitgestellte Funktionsabschluss mit dem neu verbundenen WebSocket aufgerufen. Weitere Informationen zur Verwendung dieses WebSockets zum Senden und Lesen von Nachrichten findest du weiter unten.
## Nachrichtenverkehr

Die Klasse `WebSocket` verfügt über Methoden zum Senden und Empfangen von Nachrichten, sowie zum Abhören von Ereignissen wie dem Abschluss. WebSockets können Daten über zwei Protokolle übertragen: Text und Binär. Textnachrichten werden als UTF-8-Strings interpretiert, während Binärdaten als Array von Bytes interpretiert werden.
### Nachrichtenversand

Nachrichten können über die WebSocket Methode `send` verschickt werden.

```swift
ws.send("Hello, world")
```

Die Übergabe eines `String` an diese Methode führt zum Senden einer Textnachricht. Binäre Nachrichten können durch Übergabe eines `[UInt8]` gesendet werden.
```swift
ws.send([1, 2, 3])
```

Der Nachrichtenversand erfolgt asynchron. Du kannst der Sendemethode ein `EventLoopPromise` übergeben, um benachrichtigt zu werden, wenn der Versand der Nachricht abgeschlossen ist oder der Versand fehlgeschlagen ist.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succeeded or failed to send.
}
```

Wenn du `async`/`await` verwendest, wird mit `await` auf den Abschluss des asynchronen Vorgangs zu gewartet
```swift
try await ws.send(...)
```

### Nachrichteneingang

Eingehende Nachrichten werden über die Rückrufe `onText` und `onBinary` verarbeitet.

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


Der WebSocket selbst wird als erster Parameter für diese Callbacks bereitgestellt, um Referenzzyklen zu verhindern. Verwende dafür diese Referenz, um nach dem Empfang von Daten Maßnahmen am WebSocket zu ergreifen. Um beispielsweise eine Antwort zu senden:
```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## Closing

Um den WebSocket zu schließen/beenden, rufe die Methode `close` auf.

```swift
ws.close()
```

Diese Methode gibt einen Future zurück, der abgeschlossen wird, wenn der WebSocket geschlossen wurde. Wie bei `send`, können Sie dieser Methode auch ein Promise übergeben.

```swift
ws.close(promise: nil)
```

Oder du verwendest `await` und benutzt `async`/`await`:

```swift
try await ws.close()
```

Um benachrichtigt zu werden, wenn der Peer die Verbindung schließt, verwende `onClose`. Dieses future wird abgeschlossen, wenn entweder der Client oder der Server den WebSocket schließt.
```swift
ws.onClose.whenComplete { result in
    // Succeeded or failed to close.
}
```

Die Property `closeCode` wird festgelegt, wenn der WebSocket geschlossen wird. Dies kann verwendet werden, um festzustellen, warum der Peer die Verbindung geschlossen hat.
## Ping / Pong

Ping- und Pong-Nachrichten werden automatisch vom Client und Server gesendet, um die Verbindung aufrechtzuerhalten. Unsere Anwendung kann mithilfe der Rückruf-Funktionen `onPing` und `onPong` auf diese Ereignisse reagieren.

```swift
ws.onPing { ws in 
    // Ping was received.
}

ws.onPong { ws in
    // Pong was received.
}
```
