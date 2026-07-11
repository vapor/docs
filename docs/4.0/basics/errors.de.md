# Fehlerbehandlung

Vapor baut für die Fehlerbehandlung auf Swifts `Error`-Protokoll auf. Routen-Handler können entweder einen Fehler `throw`en oder ein fehlgeschlagenes `EventLoopFuture` zurückgeben. Wird ein Swift-`Error` geworfen oder zurückgegeben, resultiert dies in einer Antwort mit dem Status `500`, und der Fehler wird protokolliert. `AbortError` und `DebuggableError` können verwendet werden, um die resultierende Antwort bzw. die Protokollierung anzupassen. Die Behandlung von Fehlern übernimmt die `ErrorMiddleware`. Diese Middleware wird standardmäßig zur Anwendung hinzugefügt und kann bei Bedarf durch eigene Logik ersetzt werden.

## Abort

Vapor stellt eine Standard-Fehlerstruktur namens `Abort` bereit. Diese Struktur ist sowohl an `AbortError` als auch an `DebuggableError` angepasst. Du kannst sie mit einem HTTP-Status und einem optionalen Fehlergrund initialisieren.

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

In alten asynchronen Situationen, in denen `throw` nicht unterstützt wird und du ein `EventLoopFuture` zurückgeben musst, wie zum Beispiel in einem `flatMap`-Closure, kannst du ein fehlgeschlagenes Future zurückgeben.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor enthält eine Hilfserweiterung zum Entpacken von Futures mit optionalen Werten: `unwrap(or:)`.

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Non-optional User supplied to closure.
}
```

Falls `User.find` `nil` zurückgibt, schlägt das Future mit dem angegebenen Fehler fehl. Andernfalls wird dem `flatMap` ein nicht-optionaler Wert übergeben. Wenn du `async`/`await` verwendest, kannst du Optionals wie gewohnt behandeln:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

Standardmäßig führt jeder Swift-`Error`, der von einem Routen-Closure geworfen oder zurückgegeben wird, zu einer `500 Internal Server Error`-Antwort. Im Debug-Modus fügt die `ErrorMiddleware` eine Beschreibung des Fehlers hinzu. Diese wird aus Sicherheitsgründen entfernt, wenn das Projekt im Release-Modus erstellt wird.

Um den resultierenden HTTP-Antwortstatus oder den Grund für einen bestimmten Fehler zu konfigurieren, passe ihn an `AbortError` an.

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## Debuggable Error

Die `ErrorMiddleware` verwendet die Methode `Logger.report(error:)`, um Fehler zu protokollieren, die von deinen Routen geworfen werden. Diese Methode prüft die Konformität zu Protokollen wie `CustomStringConvertible` und `LocalizedError`, um lesbare Meldungen zu protokollieren.

Um die Fehlerprotokollierung anzupassen, kannst du deine Fehler an `DebuggableError` anpassen. Dieses Protokoll enthält eine Reihe nützlicher Eigenschaften wie eine eindeutige Kennung, den Quellort und den Stack-Trace. Die meisten dieser Eigenschaften sind optional, was die Übernahme der Konformität einfach macht.

Um dich bestmöglich an `DebuggableError` anzupassen, sollte dein Fehler eine Struktur (`struct`) sein, damit sie bei Bedarf Informationen zu Quellort und Stack-Trace speichern kann. Im Folgenden findest du ein Beispiel für die zuvor erwähnte Enum `MyError`, die aktualisiert wurde, um eine `struct` zu verwenden und Informationen zur Fehlerquelle zu erfassen.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` besitzt mehrere weitere Eigenschaften wie `possibleCauses` und `suggestedFixes`, mit denen du die Nachvollziehbarkeit deiner Fehler verbessern kannst. Wirf einen Blick auf das Protokoll selbst, um weitere Informationen zu erhalten.

## Error Middleware

Die `ErrorMiddleware` ist eine von nur zwei Middlewares, die standardmäßig zu deiner Anwendung hinzugefügt werden. Diese Middleware wandelt Swift-Fehler, die von deinen Routen-Handlern geworfen oder zurückgegeben wurden, in HTTP-Antworten um. Ohne diese Middleware führen geworfene Fehler dazu, dass die Verbindung ohne Antwort geschlossen wird.

Um die Fehlerbehandlung über das hinaus anzupassen, was `AbortError` und `DebuggableError` bieten, kannst du die `ErrorMiddleware` durch deine eigene Fehlerbehandlungslogik ersetzen. Entferne dazu zunächst die Standard-Fehler-Middleware, indem du `app.middleware` manuell initialisierst. Füge anschließend deine eigene Fehlerbehandlungs-Middleware als erste Middleware zu deiner Anwendung hinzu.

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

Nur sehr wenige Middlewares sollten sich _vor_ der Fehlerbehandlungs-Middleware befinden. Eine bemerkenswerte Ausnahme von dieser Regel ist `CORSMiddleware`.
