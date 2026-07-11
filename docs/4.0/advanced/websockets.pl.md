# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket) umożliwiają dwukierunkową komunikację między klientem a serwerem. W przeciwieństwie do HTTP, które ma wzorzec żądania i odpowiedzi, peery WebSocket mogą wysyłać dowolną liczbę wiadomości w dowolnym kierunku. API WebSocket Vapora pozwala na tworzenie zarówno klientów, jak i serwerów, które obsługują wiadomości asynchronicznie.

## Serwer

Endpointy WebSocket mogą zostać dodane do Twojej istniejącej aplikacji Vapor za pomocą Routing API. Użyj metody `webSocket` tak, jak użyłbyś `get` lub `post`.

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

Trasy WebSocket mogą być grupowane i chronione przez middleware tak jak zwykłe trasy.

Oprócz przyjmowania przychodzącego żądania HTTP, handlery WebSocket przyjmują nowo nawiązane połączenie WebSocket. Zobacz poniżej więcej informacji na temat korzystania z tego WebSocketa do wysyłania i odczytywania wiadomości.

## Klient

Aby połączyć się ze zdalnym endpointem WebSocket, użyj `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

Metoda `connect` zwraca future, który kończy się, gdy połączenie zostanie nawiązane. Po połączeniu podane domknięcie zostanie wywołane z nowo połączonym WebSocketem. Zobacz poniżej więcej informacji na temat korzystania z tego WebSocketa do wysyłania i odczytywania wiadomości.

## Wiadomości

Klasa `WebSocket` posiada metody do wysyłania i odbierania wiadomości, a także do nasłuchiwania zdarzeń, takich jak zamknięcie. WebSockety mogą przesyłać dane za pomocą dwóch protokołów: tekstowego i binarnego. Wiadomości tekstowe są interpretowane jako ciągi UTF-8, podczas gdy dane binarne są interpretowane jako tablica bajtów.

### Wysyłanie

Wiadomości można wysyłać za pomocą metody `send` WebSocketa.

```swift
ws.send("Hello, world")
```

Przekazanie `String` do tej metody powoduje wysłanie wiadomości tekstowej. Wiadomości binarne można wysyłać, przekazując `[UInt8]`.

```swift
ws.send([1, 2, 3])
```

Wysyłanie wiadomości jest asynchroniczne. Możesz przekazać `EventLoopPromise` do metody `send`, aby zostać powiadomionym, gdy wysyłanie wiadomości zakończy się powodzeniem lub niepowodzeniem.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succeeded or failed to send.
}
```

Jeśli używasz `async`/`await`, możesz użyć `await`, aby poczekać na zakończenie operacji asynchronicznej.

```swift
try await ws.send(...)
```

### Odbieranie

Przychodzące wiadomości są obsługiwane za pomocą callbacków `onText` i `onBinary`.

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

Sam WebSocket jest przekazywany jako pierwszy parametr do tych callbacków, aby zapobiec cyklom referencji. Użyj tej referencji, aby podjąć działanie na WebSockecie po otrzymaniu danych. Na przykład, aby wysłać odpowiedź:

```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## Zamykanie

Aby zamknąć WebSocket, wywołaj metodę `close`.

```swift
ws.close()
```

Ta metoda zwraca future, który zostanie zakończony, gdy WebSocket zostanie zamknięty. Podobnie jak w przypadku `send`, możesz również przekazać do tej metody promise.

```swift
ws.close(promise: nil)
```

Lub użyj `await`, jeśli korzystasz z `async`/`await`:

```swift
try await ws.close()
```

Aby zostać powiadomionym, gdy peer zamknie połączenie, użyj `onClose`. Ten future zostanie zakończony, gdy klient lub serwer zamknie WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Succeeded or failed to close.
}
```

Właściwość `closeCode` jest ustawiana, gdy WebSocket się zamyka. Może być ona użyta do określenia, dlaczego peer zamknął połączenie.

## Ping / Pong

Wiadomości ping i pong są wysyłane automatycznie przez klienta i serwer, aby utrzymać połączenia WebSocket przy życiu. Twoja aplikacja może nasłuchiwać tych zdarzeń za pomocą callbacków `onPing` i `onPong`.

```swift
ws.onPing { ws in 
    // Ping was received.
}

ws.onPong { ws in
    // Pong was received.
}
```
