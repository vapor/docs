# Async

## Async Await

Apple hat mit Swift 5.5 die Schlüsselwörtern _async_ und _await_ eingeführt und ermöglicht damit eine neue Art der Ausführung von asynchronem Code in Swift.

Bislang konnte Vapor durch Apple's [SwiftNIO](https://github.com/apple/swift-nio.git), auf asynchrone Lösungen zurückgreifen. Absofort kann jedoch der Code mit den neuen Schlüsselwörtern versehen werden, was den Code leichter und verständlicher gestalten lässt.

Somit stehen dir in Vapor beide Möglichkeiten zur Verfügung. Es ist dir überlassen, welche du davon nutzen möchtest, allerdings empfehlen wir dir auf keinen Fall beiden Möglichkeiten miteinander zu vermischen. Anwendungen, die auf Geschwindigkeit angewiesen sind, solltest du bei _EventLoopFuture_ belassen. Zumindest bis wir die entsprechenden Methoden implementiert haben. Für alle anderen Anwendungen empfehlen wir _async/await_ zu verwenden, da die Vorteile wie beispielsweise Lesbarkeit und Wartbarkeit jeglichen Geschwindigkeitseinbußen weit überwiegen.

### Migration

Für die Migration sind ein paar Schritte zu beachten. Für macOS-Anwender ist macOS 12 Monterey (oder aktueller) und Xcode 13.1 (oder aktueller)Vorraussetzung. Für alle anderen Betriebssysteme ist Swift 5.5 (oder aktueller) Vorraussetzung. Zugleich sollten alle Abhängigkeit auf dem aktuellen Stand sein.

In your Package.swift, set the tools version to 5.5 at the top of the file:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Next, set the platform version to macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Finally update the `Run` target to mark it as an executable target:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

!!!info if you are deploying on Linux make sure you update the version of Swift there as well, e.g. on Heroku or in your Dockerfile. For example your Dockerfile would change to:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Nun kannst du mit den eigentlichen Anpassungen beginnen. Grundsätzlich kann man sagen, jede Funktion, die ein Object von Typ _EventLoopFuture_ zurückgibt, sollte mit dem Schlüsselwort _async_ versehen werden.

Beispiel:

```swift
/// EventLoopFuture
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}

/// Async/Await
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Alt und Neu

Solltest du in Vapor auf Stellen treffen, die noch kein ... kannst du die Methode _get_ verwenden, um den Wert zu wandeln.

Beispiel:

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

Can become

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

If you need to go the other way around you can convert

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

to

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## EventLoopFuture

Wie du vielleicht schon mitbekommen hast, erwarten oder liefern manche Stellen in Vapor einen Object von Typ _EventLoopFuture_. Beim ersten Mal kann das Thema verständlichlerweise verwirrent sein, weshalb wir hier nochmal auf das Thema _Futures_ eingehen möchten.

_Promises_ and _futures_ are related, but distinct, types. Mit _Promises_ werden _Futures_ erstellt. Futures are an alternative to callback-based asynchronous APIs. Futures can be chained and transformed in ways that simple closures cannot. Die meiste Zeit wirst du mit _Futures_ arbeiten, und weniger mit _Promises_

|Art              |Beschreibung                                       |Zugriff   |
|-----------------|---------------------------------------------------|----------|
|EventLoopFuture  |Reference to a value that may not be available yet.|read-only |
|EventLoopPromise |A promise to provide some value asynchronously.    |read/write|

## Wandler

Ebenso wie _Optionals_ oder _Arrays_ in Swift, können _Futures_ gemapped oder geflatmapped werden. Hauptsächlich wirst du auch diese beiden Wandler nutzen, jedoch gibt es noch mehr Wandler, die nützlich sein könnten:

|Wandler                              |Argument                   |Beschreibung                                         |
|-------------------------------------|---------------------------|-----------------------------------------------------|
|[`map`](#map)                        |`(T) -> U`                 |Maps a future value to a different value.            |
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`          |Maps a future value to a different value or an error.|
|[`flatMap`](#flatmap)                |`(T) -> EventLoopFuture<U>`|Maps a future value to different _future_ value.     |
|[`transform`](#transform)            |`U`                        |Maps a future to an already available value.         |

### map

Die Methode _map_ wandelt den zukünftigen Wert in ein anderen Wert um. Da der zukünftige Wert möglicherweise noch nicht existiert (als Ergebnis der asynchronen Ausführung), greifen wir mittels Closure auf den Wert zu.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

Die Methode _flatMapThrowing_ wandelt den zukünftigen Wert in einen anderen Wert um oder gibt einen Fehler aus.

!!! info
    Because throwing an error must create a new future internally, this method is prefixed `flatMap` even though the closure does not accept a future return.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

Die Methode _flatMap_ wandelt den Wert um und behält dabei den Status _future_. It gets the name "flat" map because it is what allows you to avoid creating nested futures (e.g., `EventLoopFuture<EventLoopFuture<T>>`). In other words, it helps you keep your generics flat.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    If we instead used `map` in the above example, we would have ended up with: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

To call a throwing method inside of a `flatMap`, use Swift's `do` / `catch` keywords and create a [completed future](#makefuture).

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

Die Methode _transform_ ändert den zukünftigen Wert ohne Beachtung des bestehenden Wertes. Das ist ziemlich nütztlich, wenn man das Ergebnis von _EventLoopFuture<Void>_ wandeln möchte.

!!! tip
    `EventLoopFuture<Void>`, sometimes called a signal, is a future whose sole purpose is to notify you of completion or failure of some async operation.

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

Trotz, dass wir der Methode im Beispiel, einen Wert mitgegeben haben, wird die Aktion vorerst nicht behandelt bis alle vorherigen Aktionen abgeschlossen oder fehlgeschlagen sind.

### Verkettung

Das Gute an den Wandlern ist, dass man sie aneinanderreihen kann, wodurch sich weitere Wandlungen und Teilaufgaben leichter schreiben lassen.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

After the initial call to map, there is a temporary `EventLoopFuture<URL>` created. This future is then immediately flat-mapped to a `EventLoopFuture<Response>`
    
## Future

Let's take a look at some other methods for using `EventLoopFuture<T>`.

### makeFuture

You can use an event loop to create pre-completed future with either the value or an error.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete


You can use `whenComplete` to add a callback that will be executed when the future succeeds or fails.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    You can add as many callbacks to a future as you want.
    
### Wait

Die Methode _wait_ kann dazu verwendet werden, auf den zukünftigen Wert zu warten. Dadurch, dass die Ausführung fehlschlagen kann, wirft die Methode den Fehler. Die Methode kann auf einem Thread im Hintergrund oder auf dem Hauptthread verwendet werden, allerdings nicht auf einem Thread einer Ereignisschleife. Das würde zu seinem Fehler führen.

You can use `.wait()` to synchronously wait for the future to be completed. Since a future may fail, this call is throwing.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()

print(string) /// String
```

## Vesprechen

Manchmal kann es vorkommen, dass du ein _Vesprechen_ erstellen musst. Zum Erstellen, benötigst du eine Ereignisschleife. Abhängig von der Platzierung kannst du über die Instanzen _Application_ oder _Request_ auf ein solche Schleife zugreifen.

Beispiel:

```swift
let eventLoop: EventLoop 

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)

print(promiseString) // EventLoopPromise<String>

print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    A promise can only be completed once. Any subsequent completions will be ignored.

Versprechen können mit dem Status _succeed_ oder _fail_ abschließen und ist der Grund, warum für die Erstellung, eine Ereignisschleife benötigt wird. Damit das Ergebnis nach Abschluss durch die Schleife ausgeführt werden kann.

## Event Loop

Mit dem Starten deiner Anwendung wird für jeden Prozessorkern einen Ereignisschleife erstellt. Jede Ereignisschleife hat genau einen Thread. Die Ereignisschleifen in Vapor sind ähnlich zu den Ereignisschleifen in Node.js, außer das Vapor durch Swift`s Multi-Threading mehrere Schleifen gleichzeitig verarbeiten kann.

Jede Verbindung zum Server wird einer Ereignisschleife zugewiesen. Ab dem Zeitpunkt läuft die Kommunikation zwischen Server und Client immer über die selbe Schleife.

Die Ereignischleife ist für die Überwachung des Zustands verantwortlich. Sollte einen Anfrage vom Client darauf warten gelesen zu werden, macht sich die Schleife bemerkbar, wodurch anschließend die Daten gelesen werden. Once the entire request is read, any futures waiting for that request's data will be completed.  

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor expects that route closures will stay on `req.eventLoop`. If you hop threads, you must ensure access to `Request` and the final response future all happen on the request's event loop. 

Outside of route closures, you can get one of the available event loops via `Application`. 

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### Hüpfen

Mit der Methode _hop_ kannst du die Ereignisschleife wechseln.

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

Die Verwendung von Blocking Code auf einem Thread der Ereignisschleife, kann dazu führen, dass die Anwendung nicht in angemessener Zeit auf die eingehende Anfrage reagieren kann.

Ein Beispiel für Blocking Code ist:

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

Die Methode `sleep(_:)` blockiert den aktuellen Thread für zu angegebenen Sekunden. Durch die Verwendung auf einer Ereignisschleife, kann die Schleife nicht

`sleep(_:)` is a command that blocks the current thread for the number of seconds supplied. If you do blocking work like this directly on an event loop, the event loop will be unable to respond to any other clients assigned to it for the duration of the blocking work. In other words, if you do `sleep(5)` on an event loop, all of the other clients connected to that event loop (possibly hundreds or thousands) will be delayed for at least 5 seconds. 

Make sure to run any blocking work in the background. Use promises to notify the event loop when this work is done in a non-blocking way.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

Not all blocking calls will be as obvious as `sleep(_:)`. If you are suspicious that a call you are using may be blocking, research the method itself or ask someone. The sections below go over how methods can block in more detail.

### I/O Bound

Blockieren von I/O Bound bedeutet warten auf einer

I/O bound blocking means waiting on a slow resource like a network or hard disk which can be orders of magnitude slower than the CPU. Blocking the CPU while you wait for these resources results in wasted time. 

!!! danger
    Never make blocking I/O bound calls directly on an event loop.

All of Vapor's packages are built on SwiftNIO and use non-blocking I/O. However, there are many Swift packages and C libraries in the wild that use blocking I/O. Chances are if a function is doing disk or network IO and uses a synchronous API (no callbacks or futures) it is blocking.
    
### CPU Bound

Meist während einer Serveranfrage wird auf das Ergebnis weiterer Datenbank- oder Netzwerkanfrage gewartet. Vapor und SwiftNIO sind non-blocking, was bedeutet, dass eben diese Wartezeit für die Bearbeitung anderer Anfragen genutzt werden kann. Jedoch kann es auch zu leistungsintensiven Anfragen kommen.

Wenn eine Ereignisschleife eben ein solche leistungsintensive Arbeit verrichtet, ist sie nicht in der Lage auf andere eingehende Anfragen zu reagieren. Normalerweise ist das kein Problem, da heutzutage Prozessoren schnell sind und Webanwendungen weniger prozessorlastige Arbeiten verrichten.
Aber es kann zu einem Problem werden, wenn eine Anfrage, andere Anfragen blockiert.

Das Auffinden leistungsintensiver Anfragen und Verlagern auf einem Thread im Hintergrund kann die Zuverlässigkeit und Reaktionsfähigkeit deiner Anwendungen verbessern. CPU bound work is more of a gray area than I/O bound work, and it is ultimately up to you to determine where you want to draw the line. 

Ein gängiges Beispiel für eine leistungsintensive Anfrage is das Bcrypt-Hashing während einer Benutzeranmeldung. Bcrypt ist aus Sicherheitsgründen absichtlich sehr langsam und leistungsintensiv. Durch das Verlagern des Hashings auf einem Thread im Hintergrund kann der Prozessor, während der Berechnung, mit der Ereignisschleife weiter fortfahren.
