# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket) maken tweerichtingscommunicatie tussen een client en server mogelijk. In tegenstelling tot HTTP, dat een verzoek en antwoord patroon heeft, kunnen WebSocket peers een willekeurig aantal berichten in beide richtingen sturen. Vapor's WebSocket API maakt het mogelijk om zowel clients als servers te maken die berichten asynchroon afhandelen.

## Server

WebSocket endpoints kunnen worden toegevoegd aan uw bestaande Vapor applicatie met behulp van de Routing API. Gebruik de `webSocket` methode zoals u `get` of `post` zou gebruiken. 

```swift
app.webSocket("echo") { req, ws in
    // Verbonden WebSocket.
    print(ws)
}
```

WebSocket routes kunnen worden gegroepeerd en worden beschermd door middleware zoals normale routes. 

Naast het accepteren van het inkomende HTTP verzoek, accepteren WebSocket handlers ook de nieuw opgezette WebSocket verbinding. Zie hieronder voor meer informatie over het gebruik van deze WebSocket voor het verzenden en lezen van berichten.

## Client

Om verbinding te maken met een WebSocket eindpunt op afstand, gebruik `WebSocket.connect`. 

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Verbonden WebSocket.
    print(ws)
}
```

De `connect` methode retourneert een future die wordt afgesloten als de verbinding tot stand is gebracht. Eenmaal verbonden zal de meegeleverde closure aangeroepen worden met de zojuist verbonden WebSocket. Zie hieronder voor meer informatie over het gebruik van deze WebSocket om berichten te versturen en te lezen.

## Berichten

De `WebSocket` klasse heeft methoden voor het zenden en ontvangen van berichten en voor het luisteren naar gebeurtenissen zoals sluiting. WebSockets kunnen gegevens verzenden via twee protocollen: tekst en binair. Tekst berichten worden geïnterpreteerd als UTF-8 strings, terwijl binaire gegevens worden geïnterpreteerd als een array van bytes.

### Versturen

Berichten kunnen worden verzonden met de WebSocket `send` methode.

```swift
ws.send("Hello, world")
```

Het doorgeven van een `String` aan deze methode resulteert in het versturen van een tekst bericht. Binaire berichten kunnen worden verzonden door een `[UInt8]` door te geven. 

```swift
ws.send([1, 2, 3])
```

Het verzenden van berichten is asynchroon. Je kunt een `EventLoopPromise` meegeven aan de send method om een bericht te krijgen wanneer het bericht klaar is met verzenden of wanneer het verzenden mislukt is. 

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Is gelukt of niet gelukt om te verzenden.
}
```

Als u `async`/`await` gebruikt kunt u "wachten" op het resultaat

```swift
// TODO Check this actually works
let result = try await ws.send(...)
```

### Ontvangen

Inkomende berichten worden afgehandeld via de `onText` en `onBinary` callbacks.

```swift
ws.onText { ws, text in
    // String ontvangen door deze WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] ontvangen door deze WebSocket.
    print(binary)
}
```

De WebSocket zelf wordt als eerste parameter aan deze callbacks meegegeven om referentie cycli te voorkomen. Gebruik deze referentie om actie te ondernemen op de WebSocket na ontvangst van data. Bijvoorbeeld om een antwoord te sturen:

```swift
// Echo's van ontvangen berichten.
ws.onText { ws, text in
    ws.send(text)
}
```

## Afsluiten

Om een WebSocket af te sluiten, roep de `close` methode op. 

```swift
ws.close()
```

Deze methode retourneert een future die voltooid zal worden als de WebSocket gesloten is. Net als `send`, mag je ook een promise doorgeven aan deze methode.

```swift
ws.close(promise: nil)
```

Of "wacht" erop als je `async`/`await` gebruikt:

```swift
try await ws.close()
```

Om een melding te krijgen wanneer de peer de verbinding sluit, gebruik `onClose`. Deze future wordt uitgevoerd wanneer ofwel de client ofwel de server de WebSocket sluit.

```swift
ws.onClose.whenComplete { result in
    // Geslaagd of mislukt om te sluiten.
}
```

De `closeCode` eigenschap wordt ingesteld wanneer de WebSocket sluit. Dit kan gebruikt worden om te bepalen waarom de peer de verbinding heeft gesloten.

## Ping / Pong

Ping en pong berichten worden automatisch verzonden door de client en server om WebSocket verbindingen in leven te houden. Je applicatie kan luisteren naar deze events door gebruik te maken van de `onPing` en `onPong` callbacks.

```swift
ws.onPing { ws in 
    // Ping is ontvangen.
}

ws.onPong { ws in
    // Pong werd ontvangen.
}
```
