# Errori

Vapor si basa sul protocollo `Error` di Swift per la gestione degli errori. Gli handler delle route possono sia lanciare (`throw`) un errore che restituire un `EventLoopFuture` fallito. Lanciare o restituire un `Error` di Swift risulterà in una risposta con stato `500` e l'errore verrà registrato nel log. `AbortError` e `DebuggableError` possono essere usati per cambiare rispettivamente la risposta risultante e il logging. La gestione degli errori è affidata a `ErrorMiddleware`. Questo middleware viene aggiunto all'applicazione per impostazione predefinita e può essere sostituito con logica personalizzata se desiderato.

## Abort

Vapor fornisce una struct di errore predefinita chiamata `Abort`. Questa struct è conforme sia a `AbortError` che a `DebuggableError`. Puoi inizializzarla con uno stato HTTP e un motivo di fallimento opzionale.

```swift
// Errore 404, viene usato il motivo predefinito "Not Found".
throw Abort(.notFound)

// Errore 401, viene usato un motivo personalizzato.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

In situazioni asincrone precedenti dove il lancio di eccezioni non è supportato e devi restituire un `EventLoopFuture`, come in una closure `flatMap`, puoi restituire una future fallita.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))
}
return user.save()
```

Vapor include un'estensione helper per estrarre future con valori opzionali: `unwrap(or:)`.

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap
{ user in
    // User non-opzionale fornito alla closure.
}
```

Se `User.find` restituisce `nil`, la future fallirà con l'errore fornito. Altrimenti, il `flatMap` riceverà un valore non opzionale. Se si usa `async`/`await` è possibile gestire gli opzionali normalmente:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```

## Abort Error

Per impostazione predefinita, qualsiasi `Error` Swift lanciato o restituito da una closure di route risulterà in una risposta `500 Internal Server Error`. Quando compilato in modalità debug, `ErrorMiddleware` includerà una descrizione dell'errore. Questa viene rimossa per ragioni di sicurezza quando il progetto viene compilato in modalità release.

Per configurare lo stato HTTP della risposta risultante o il motivo per un particolare errore, conformalo a `AbortError`.

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

`ErrorMiddleware` usa il metodo `Logger.report(error:)` per registrare nel log gli errori lanciati dalle tue route. Questo metodo verificherà la conformità a protocolli come `CustomStringConvertible` e `LocalizedError` per registrare messaggi leggibili.

Per personalizzare il logging degli errori, puoi conformare i tuoi errori a `DebuggableError`. Questo protocollo include una serie di proprietà utili come un identificatore univoco, la posizione nel codice sorgente e lo stack trace. La maggior parte di queste proprietà è opzionale, il che rende facile adottare la conformità.

Per essere conformi al meglio a `DebuggableError`, il tuo errore dovrebbe essere una struct in modo da poter memorizzare informazioni sulla sorgente e sullo stack trace se necessario. Di seguito è riportato un esempio dell'enum `MyError` precedentemente menzionato aggiornato per usare una `struct` e acquisire informazioni sulla sorgente dell'errore.

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

`DebuggableError` ha molte altre proprietà come `possibleCauses` e `suggestedFixes` che puoi usare per migliorare la risolvibilità dei tuoi errori. Dai un'occhiata al protocollo stesso per maggiori informazioni.

## Error Middleware

`ErrorMiddleware` è uno dei soli due middleware aggiunti alla tua applicazione per impostazione predefinita. Questo middleware converte gli errori Swift che sono stati lanciati o restituiti dai tuoi route handler in risposte HTTP. Senza questo middleware, gli errori lanciati risulteranno nella chiusura della connessione senza una risposta.

Per personalizzare la gestione degli errori al di là di quanto fornito da `AbortError` e `DebuggableError`, puoi sostituire `ErrorMiddleware` con la tua logica di gestione degli errori. Per farlo, prima rimuovi il middleware di errore predefinito inizializzando manualmente `app.middleware`. Poi, aggiungi il tuo middleware di gestione degli errori come primo middleware alla tua applicazione.

```swift
// Cancella tutti i middleware predefiniti (poi, riaggiungi il route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Aggiungi il middleware di gestione degli errori personalizzato per primo.
app.middleware.use(MyErrorMiddleware())
```

Pochissimi middleware dovrebbero andare _prima_ del middleware di gestione degli errori. Un'eccezione degna di nota a questa regola è `CORSMiddleware`.
