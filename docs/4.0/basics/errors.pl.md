# Błędy

Vapor bazuje na protokole `Error` w Swifcie do obsługi błędów. Handlery tras mogą albo rzucić (`throw`) błąd, albo zwrócić nieudane (failed) `EventLoopFuture`. Rzucenie lub zwrócenie błędu typu `Error` w Swifcie spowoduje odpowiedź ze statusem `500`, a błąd zostanie zalogowany. `AbortError` i `DebuggableError` mogą zostać użyte do zmiany, odpowiednio, wynikowej odpowiedzi i logowania. Obsługą błędów zajmuje się `ErrorMiddleware`. To middleware jest domyślnie dodawane do aplikacji i w razie potrzeby może zostać zastąpione niestandardową logiką.

## Abort

Vapor udostępnia domyślną strukturę błędu o nazwie `Abort`. Ta struktura jest zgodna zarówno z `AbortError`, jak i `DebuggableError`. Możesz ją zainicjalizować za pomocą statusu HTTP oraz opcjonalnego powodu niepowodzenia.

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

W starszych sytuacjach asynchronicznych, w których rzucanie błędów nie jest wspierane i musisz zwrócić `EventLoopFuture`, jak na przykład w domknięciu `flatMap`, możesz zwrócić nieudane future.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor zawiera pomocnicze rozszerzenie do rozpakowywania future'ów z opcjonalnymi wartościami: `unwrap(or:)`.

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Non-optional User supplied to closure.
}
```

Jeśli `User.find` zwróci `nil`, future zakończy się niepowodzeniem z podanym błędem. W przeciwnym razie do `flatMap` zostanie przekazana wartość nieopcjonalna. Jeśli korzystasz z `async`/`await`, możesz obsługiwać opcjonały w zwykły sposób:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

Domyślnie każdy błąd typu `Error` w Swifcie, rzucony lub zwrócony przez domknięcie trasy, spowoduje odpowiedź `500 Internal Server Error`. Podczas budowania w trybie debug, `ErrorMiddleware` dołączy opis błędu. Jest on usuwany ze względów bezpieczeństwa, gdy projekt jest zbudowany w trybie release.

Aby skonfigurować wynikowy status odpowiedzi HTTP lub powód dla konkretnego błędu, dostosuj go do protokołu `AbortError`.

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

`ErrorMiddleware` wykorzystuje metodę `Logger.report(error:)` do logowania błędów rzucanych przez twoje trasy. Ta metoda sprawdza zgodność z protokołami takimi jak `CustomStringConvertible` i `LocalizedError`, aby logować czytelne komunikaty.

Aby dostosować logowanie błędów, możesz dostosować swoje błędy do protokołu `DebuggableError`. Ten protokół zawiera szereg przydatnych właściwości, takich jak unikalny identyfikator, lokalizacja źródłowa oraz stack trace. Większość tych właściwości jest opcjonalna, co ułatwia przyjęcie zgodności.

Aby jak najlepiej dostosować się do `DebuggableError`, twój błąd powinien być strukturą (`struct`), dzięki czemu w razie potrzeby może przechowywać informacje o źródle i stack trace. Poniżej znajduje się przykład wspomnianego wcześniej enuma `MyError`, zaktualizowanego tak, aby korzystał ze `struct` i przechwytywał informacje o źródle błędu.

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

`DebuggableError` posiada kilka innych właściwości, takich jak `possibleCauses` i `suggestedFixes`, których możesz użyć, aby poprawić możliwość debugowania swoich błędów. Zajrzyj do samego protokołu, aby dowiedzieć się więcej.

## Error Middleware

`ErrorMiddleware` jest jednym z zaledwie dwóch middleware'ów domyślnie dodawanych do twojej aplikacji. To middleware konwertuje błędy Swifta rzucone lub zwrócone przez handlery twoich tras na odpowiedzi HTTP. Bez tego middleware'u rzucone błędy spowodują zamknięcie połączenia bez żadnej odpowiedzi.

Aby dostosować obsługę błędów w większym zakresie niż pozwalają na to `AbortError` i `DebuggableError`, możesz zastąpić `ErrorMiddleware` własną logiką obsługi błędów. Aby to zrobić, najpierw usuń domyślne middleware błędów, ręcznie inicjalizując `app.middleware`. Następnie dodaj własne middleware obsługi błędów jako pierwsze middleware w swojej aplikacji.

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

Bardzo niewiele middleware'ów powinno znajdować się _przed_ middleware'em obsługi błędów. Godnym uwagi wyjątkiem od tej reguły jest `CORSMiddleware`.
