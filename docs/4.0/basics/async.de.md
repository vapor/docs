# Async

## Async Await

Apple hat mit Swift 5.5 die Schlüsselwörtern _async_ und _await_ eingeführt und ermöglicht damit eine neue Art der asynchronen Ausführung von Code.

Bislang konnte Vapor durch Apple's [SwiftNIO](https://github.com/apple/swift-nio.git) auf asynchrone Lösungen zurückgreifen. 

Absofort kann der Code jedoch mit den neuen Schlüsselwörtern versehen werden, was ihn leichter und verständlicher gestalten lässt. 

In Vapor stehen dir also beide Möglichkeiten der asynchronen Ausführung zur Verfügung. Es ist nun dir überlassen, welche du davon nutzen möchtest, allerdings empfehlen wir dir auf keinen Fall beiden Möglichkeiten miteinander zu vermischen.

Anwendungen, die auf Leistung angewiesen sind, solltest du bei _EventLoopFuture_ belassen. Zumindest bis wir die entsprechenden Methoden implementiert haben. 

Für alle anderen Anwendungen empfehlen wir _async/await_ zu verwenden, da die Vorteile wie beispielsweise Lesbarkeit und Wartbarkeit jeglichen Geschwindigkeitseinbußen weit überwiegen.

### Migration

Für die Migration auf _async/await_ sind ein paar Dinge zu beachten. 

Für Anwender von macOS ist macOS 12 Monterey (oder aktueller) und Xcode 13.1 (oder aktueller) erforderlich. Für alle anderen Betriebssysteme ist Swift 5.5 (oder aktueller) Vorraussetzung. 

Zugleich sollten alle Abhängigkeit auf dem aktuellen Stand sein.

Hebe die Mindestversion für Swift Tools in der ersten Zeile deiner Paketbeschreibung auf 5.5 an.

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Hebe die Mindestversion für den Parameter Platforms auf macOS 12 an.

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Aktualisiere abschließend das `Run`-Target, um es als ausführbares Target zu kennzeichnen:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Hinweis: Wenn du auf Linux deployst, stelle sicher, dass du dort ebenfalls die Swift-Version aktualisierst, z. B. auf Heroku oder in deinem Dockerfile. Zum Beispiel würde sich dein Dockerfile wie folgt ändern:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Nun kannst du mit den eigentlichen Anpassungen beginnen. 

Grundsätzlich kann man sagen, jede Funktion, die ein Objekt vom Typ _EventLoopFuture_ zurückgibt, ist nun `async`. Zum Beispiel:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Wird zu:

```swift
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

Solltest du auf APIs treffen, die noch keine `async`/`await`-Version anbieten, kannst du `.get()` auf einer Funktion aufrufen, die ein `EventLoopFuture` zurückgibt, um es umzuwandeln.

Z. B.

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

Kann werden zu

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Wenn du den umgekehrten Weg gehen musst, kannst du

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

umwandeln zu

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`s

Wie du vielleicht schon an der ein oder anderen Stelle gesehen hast, erwarten oder liefern manche Methoden in Vapor einen Object von Typ _EventLoopFuture_. 

Beim ersten Mal kann das Thema verständlichlerweise verwirrent sein, weshalb wir hier nochmal auf das Thema _Futures_ eingehen möchten.

Promises und Futures sind verwandte, aber unterschiedliche Typen. Mit _Promises_ werden _Futures_ erstellt. Die meiste Zeit wirst du mit _Futures_ arbeiten, die von Vapors APIs zurückgegeben werden, und musst dich nicht darum kümmern, selbst _Promises_ zu erstellen.

|Art              |Beschreibung                                                     |Zugriff           |
|-----------------|------------------------------------------------------------------|------------------|
|`EventLoopFuture`|Referenz auf einen Wert, der eventuell noch nicht verfügbar ist.   |nur lesend        |
|`EventLoopPromise`|Ein Versprechen, einen Wert zu einem späteren Zeitpunkt asynchron bereitzustellen.|lesend/schreibend|

Futures sind eine Alternative zu callback-basierten asynchronen APIs. Futures können verkettet und transformiert werden, auf eine Weise, wie es mit einfachen Closures nicht möglich ist.

## Wandler

Ebenso wie _Optionals_ oder _Arrays_ in Swift, können _Futures_ gemapped oder geflatmapped werden. Hauptsächlich wirst du diese beiden Wandler nutzen, jedoch gibt es noch weitere Wandler, die für dich nützlich sein könnten:

|Wandler                              |Argument                   |Beschreibung                                         |
|-------------------------------------|---------------------------|-----------------------------------------------------|
|[`map`](#map)                        |`(T) -> U`                 |Wandelt einen zukünftigen Wert in einen anderen Wert um.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`          |Wandelt einen zukünftigen Wert in einen anderen Wert um oder wirft einen Fehler.|
|[`flatMap`](#flatmap)                |`(T) -> EventLoopFuture<U>`|Wandelt einen zukünftigen Wert in einen anderen zukünftigen Wert um.|
|[`transform`](#transform)            |`U`                        |Wandelt ein Future in einen bereits verfügbaren Wert um.|

Wenn du dir die Methodensignaturen von `map` und `flatMap` bei `Optional<T>` und `Array<T>` ansiehst, wirst du feststellen, dass sie den auf `EventLoopFuture<T>` verfügbaren Methoden sehr ähnlich sind.

### map

Die Methode _map_ wandelt den zukünftigen Wert in ein anderen Wert um. Da der zukünftige Wert möglicherweise noch nicht existiert (als Ergebnis der asynchronen Ausführung), greifen wir in der Klammer auf den Wert zu.

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
    Da das Werfen eines Fehlers intern ein neues Future erzeugen muss, ist die Methode mit `flatMap` präfixiert, obwohl der Closure keinen Future-Rückgabewert akzeptiert.

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

Die Methode _flatMap_ wandelt den Wert um und behält dabei den Status _future_. Sie wird "flat" map genannt, weil sie es dir ermöglicht, verschachtelte Futures zu vermeiden (z. B. `EventLoopFuture<EventLoopFuture<T>>`). Mit anderen Worten: Sie hilft dir dabei, deine Generics flach zu halten.

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
    Hätten wir stattdessen im obigen Beispiel `map` verwendet, wären wir bei `EventLoopFuture<EventLoopFuture<ClientResponse>>` gelandet.

Um eine werfende (throwing) Methode innerhalb eines `flatMap` aufzurufen, verwende Swifts `do`/`catch`-Schlüsselwörter und erstelle ein [abgeschlossenes Future](#makefuture).

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
    `EventLoopFuture<Void>`, manchmal auch als Signal bezeichnet, ist ein Future, dessen einziger Zweck es ist, dich über den Abschluss oder das Fehlschlagen einer asynchronen Operation zu informieren.

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

Lass uns die Beispiele von oben abändern, um zu sehen, wie wir von der Verkettung profitieren können.

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

Nach dem anfänglichen Aufruf von `map` wird ein temporäres `EventLoopFuture<URL>` erzeugt. Dieses Future wird dann sofort zu einem `EventLoopFuture<Response>` flat-gemappt.
    
## Future

Werfen wir einen Blick auf einige weitere Methoden für die Verwendung von `EventLoopFuture<T>`.

### makeFuture

Du kannst eine Ereignisschleife verwenden, um ein bereits abgeschlossenes Future zu erstellen, das entweder einen Wert oder einen Fehler enthält.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

Du kannst `whenComplete` verwenden, um einen Callback hinzuzufügen, der ausgeführt wird, wenn das Future erfolgreich abgeschlossen wird oder fehlschlägt.

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
    Du kannst einem Future so viele Callbacks hinzufügen, wie du möchtest.

### Get

Falls es für eine API (noch) keine Alternative auf Basis von Concurrency gibt, kannst du mit `try await future.get()` auf den Wert des Future warten.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Wait for the string to be ready
let string: String = try await futureString.get()
print(string) /// String
```
    
### Wait

!!! warning
    Die Funktion `wait()` ist veraltet, siehe [`Get`](#get) für den empfohlenen Ansatz.

Du kannst `.wait()` verwenden, um synchron auf den Abschluss des Future zu warten. Da ein Future fehlschlagen kann, ist dieser Aufruf werfend (throwing).

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()` kann nur auf einem Hintergrund-Thread oder dem Haupt-Thread verwendet werden, d. h. in `configure.swift`. Es kann _nicht_ auf einem Ereignisschleifen-Thread verwendet werden, d. h. in Route-Closures.

!!! warning
    Der Versuch, `wait()` auf einem Ereignisschleifen-Thread aufzurufen, führt zu einem Assertion-Fehler.
    
## Versprechen

Manchmal kann es vorkommen, dass du ein _Versprechen_ erstellen musst. Zum Erstellen, benötigst du eine Ereignisschleife. Abhängig von der Platzierung kannst du über die Instanzen _Application_ oder _Request_ auf ein solche Schleife zugreifen.

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
    Ein Versprechen kann nur einmal abgeschlossen werden. Alle nachfolgenden Abschlüsse werden ignoriert.

Versprechen können mit dem Status _succeed_ oder _fail_ abschließen und ist der Grund, warum für die Erstellung, eine Ereignisschleife benötigt wird. Damit das Ergebnis nach Abschluss durch die Schleife ausgeführt werden kann.

## Event Loop

Mit dem Starten deiner Anwendung wird für jeden Prozessorkern eine Ereignisschleife erstellt. Jede Ereignisschleife hat genau einen Thread. Die Ereignisschleifen in Vapor sind ähnlich zu den Ereignisschleifen in Node.js, außer das Vapor durch Swift`s Multi-Threading mehrere Schleifen gleichzeitig verarbeiten kann.

Jede Verbindung zum Server wird einer Ereignisschleife zugewiesen. Ab dem Zeitpunkt läuft die Kommunikation zwischen Server und Client immer über die selbe Schleife.

Die Ereignischleife ist für die Überwachung des Zustands verantwortlich. Sollte einen Anfrage vom Client darauf warten gelesen zu werden, macht sich die Schleife bemerkbar, wodurch anschließend die Daten gelesen werden. Sobald die gesamte Anfrage gelesen wurde, werden alle Futures abgeschlossen, die auf die Daten dieser Anfrage gewartet haben.

In Route-Closures kannst du über `Request` auf die aktuelle Ereignisschleife zugreifen.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor erwartet, dass Route-Closures auf `req.eventLoop` bleiben. Falls du zwischen Threads wechselst, musst du sicherstellen, dass der Zugriff auf `Request` und das abschließende Response-Future alle auf der Ereignisschleife der Anfrage stattfinden.

Außerhalb von Route-Closures kannst du über `Application` eine der verfügbaren Ereignisschleifen bekommen.

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

Die Methode `sleep(_:)` blockiert den aktuellen Thread für die angegebene Anzahl an Sekunden. Wenn du solche blockierende Arbeit direkt auf einer Ereignisschleife ausführst, kann die Ereignisschleife für die Dauer dieser Arbeit nicht auf andere ihr zugewiesene Clients reagieren. Mit anderen Worten: Wenn du `sleep(5)` auf einer Ereignisschleife aufrufst, werden alle anderen mit dieser Ereignisschleife verbundenen Clients (möglicherweise Hunderte oder Tausende) um mindestens 5 Sekunden verzögert.

Achte darauf, blockierende Arbeit im Hintergrund auszuführen. Verwende Versprechen, um die Ereignisschleife auf nicht-blockierende Weise zu benachrichtigen, sobald diese Arbeit abgeschlossen ist.

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

Nicht alle blockierenden Aufrufe sind so offensichtlich wie `sleep(_:)`. Wenn du vermutest, dass ein von dir verwendeter Aufruf blockierend sein könnte, informiere dich über die Methode oder frage jemanden. Die folgenden Abschnitte gehen genauer darauf ein, wie Methoden blockieren können.

### I/O Bound

I/O-bound Blocking bedeutet, dass auf eine langsame Ressource wie ein Netzwerk oder eine Festplatte gewartet wird, die um Größenordnungen langsamer sein kann als die CPU. Die CPU zu blockieren, während auf diese Ressourcen gewartet wird, führt zu verschwendeter Zeit.

!!! danger
    Führe niemals blockierende I/O-bound Aufrufe direkt auf einer Ereignisschleife aus.

Alle Pakete von Vapor bauen auf SwiftNIO auf und verwenden nicht-blockierendes I/O. Es gibt jedoch viele Swift-Pakete und C-Bibliotheken, die blockierendes I/O verwenden. Die Wahrscheinlichkeit ist hoch, dass eine Funktion blockierend ist, wenn sie Festplatten- oder Netzwerk-I/O durchführt und dabei eine synchrone API (ohne Callbacks oder Futures) verwendet.
    
### CPU Bound

Meist während einer Serveranfrage wird auf das Ergebnis weiterer Datenbank- oder Netzwerkanfrage gewartet. 

Vapor und SwiftNIO sind non-blocking, was bedeutet, dass eben diese Wartezeit für die Bearbeitung anderer Anfragen genutzt werden kann. 

Jedoch kann es auch zu leistungsintensiveren Anfragen kommen.

Wenn eine Ereignisschleife eben ein solche leistungsintensive Arbeit verrichtet, ist sie nicht in der Lage auf andere eingehende Anfragen zu reagieren. 

Normalerweise ist das kein Problem, da heutzutage Prozessoren schnell sind und Webanwendungen weniger prozessorlastige Arbeiten verrichten.
Aber es kann zu einem Problem werden, wenn eine Anfrage, andere Anfragen blockiert.

Das Auffinden leistungsintensiver Anfragen und Verlagern auf einem Thread im Hintergrund kann die Zuverlässigkeit und Reaktionsfähigkeit deiner Anwendungen verbessern. CPU-bound Arbeit ist eher ein Graubereich im Vergleich zu I/O-bound Arbeit, und es liegt letztlich an dir zu entscheiden, wo du die Grenze ziehen möchtest.

Ein gängiges Beispiel für eine leistungsintensive Anfrage ist das Bcrypt-Hashing während einer Benutzeranmeldung. Bcrypt ist aus Sicherheitsgründen absichtlich sehr langsam und leistungsintensiv. Das könnte die rechenintensivste Arbeit sein, die eine einfache Webanwendung tatsächlich ausführt. Durch das Verlagern des Hashings auf einen Hintergrund-Thread kann der Prozessor während der Berechnung mit der Arbeit der Ereignisschleife fortfahren, was zu einer höheren Nebenläufigkeit führt.
