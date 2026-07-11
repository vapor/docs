# Services

Vapors `Application` und `Request` sind so gebaut, dass sie von deiner Anwendung und Drittanbieter-Paketen erweitert werden können. Neue Funktionalität, die diesen Typen hinzugefügt wird, wird oft als Service bezeichnet.

## Read Only

Der einfachste Typ von Service ist read-only. Diese Services bestehen aus berechneten Variablen oder Methoden, die entweder Application oder Request hinzugefügt werden.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

Read-only-Services können von jedem bereits vorhandenen Service abhängen, wie z. B. `client` in diesem Beispiel. Sobald die Extension hinzugefügt wurde, kann dein eigener Service wie jede andere Property auf Request verwendet werden.

```swift
req.myAPI.foos()
```

## Schreibbar

Services, die einen Zustand oder eine Konfiguration benötigen, können den `Application`- und `Request`-Storage zum Speichern von Daten nutzen. Nehmen wir an, du möchtest die folgende `MyConfiguration`-Struct zu deiner Anwendung hinzufügen.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Um den Storage zu verwenden, musst du einen `StorageKey` deklarieren.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Dies ist eine leere Struct mit einem `Value`-Typealias, der angibt, welcher Typ gespeichert wird. Indem du einen leeren Typ als Key verwendest, kannst du kontrollieren, welcher Code Zugriff auf deinen Storage-Wert hat. Wenn der Typ `internal` oder `private` ist, kann nur dein eigener Code den zugehörigen Wert im Storage ändern.

Füge abschließend eine Extension zu `Application` hinzu, um die `MyConfiguration`-Struct zu lesen und zu setzen.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

Sobald die Extension hinzugefügt wurde, kannst du `myConfiguration` wie eine normale Property auf `Application` verwenden.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Lifecycle

Vapors `Application` erlaubt es dir, Lifecycle-Handler zu registrieren. Damit kannst du dich in Ereignisse wie Boot und Shutdown einklinken.

```swift
// Prints hello during boot.
struct Hello: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Called after application boots.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Called before application shutdown.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Add lifecycle handler.
app.lifecycle.use(Hello())
```

## Locks

Vapors `Application` enthält praktische Hilfsmittel, um Code mithilfe von Locks zu synchronisieren. Indem du einen `LockKey` deklarierst, erhältst du ein eindeutiges, gemeinsam genutztes Lock, um den Zugriff auf deinen Code zu synchronisieren.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Do something.
}
```

Jeder Aufruf von `lock(for:)` mit demselben `LockKey` gibt dasselbe Lock zurück. Diese Methode ist thread-safe.

Für ein anwendungsweites Lock kannst du `app.sync` verwenden.

```swift
app.sync.withLock {
    // Do something.
}
```

## Request

Services, die in Route-Handlern verwendet werden sollen, sollten `Request` hinzugefügt werden. Request-Services sollten den Logger und die Event Loop des Requests verwenden. Es ist wichtig, dass ein Request auf derselben Event Loop bleibt, da sonst eine Assertion ausgelöst wird, wenn die Response an Vapor zurückgegeben wird.

Wenn ein Service die Event Loop des Requests verlassen muss, um Arbeit zu erledigen, sollte er sicherstellen, dass er zur Event Loop zurückkehrt, bevor er fertig ist. Dies kann mit `hop(to:)` auf `EventLoopFuture` erreicht werden.

Request-Services, die Zugriff auf Application-Services benötigen, wie z. B. Konfigurationen, können `req.application` verwenden. Achte dabei auf Thread-Safety, wenn du von einem Route-Handler aus auf die Application zugreifst. Im Allgemeinen sollten von Requests nur Leseoperationen durchgeführt werden. Schreiboperationen müssen durch Locks geschützt werden.
