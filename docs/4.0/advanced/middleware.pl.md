# Middleware

Middleware to łańcuch logiki pomiędzy klientem a handlerem trasy Vapor. Pozwala on na wykonywanie operacji na przychodzących zapytaniach, zanim dotrą one do handlera trasy, oraz na wychodzących odpowiedziach, zanim trafią one do klienta.

## Konfiguracja

Middleware może być zarejestrowany globalnie (na każdej trasie) w `configure(_:)` przy użyciu `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

Możesz również dodać middleware do poszczególnych tras, korzystając z grup tras.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
    // This request has passed through MyMiddleware.
}
```

### Kolejność

Kolejność, w jakiej dodawane są middleware, ma znaczenie. Zapytania trafiające do twojej aplikacji będą przechodzić przez middleware w kolejności, w jakiej zostały dodane. Odpowiedzi opuszczające twoją aplikację będą przechodzić przez nie w odwrotnej kolejności. Middleware specyficzny dla trasy zawsze uruchamia się po middleware aplikacji. Weźmy poniższy przykład:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
    $0.get("hello") { req in
        "Hello, middleware."
    }
}
```

Zapytanie do `GET /hello` odwiedzi middleware w następującej kolejności:

```
Request → A → B → C → Handler → C → B → A → Response
```

Middleware może być również _dodawany na początek_, co jest przydatne, gdy chcesz dodać middleware _przed_ domyślnym middleware, który Vapor dodaje automatycznie:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Tworzenie middleware

Vapor jest wyposażony w kilka przydatnych middleware, ale możesz potrzebować stworzyć własny ze względu na wymagania twojej aplikacji. Możesz na przykład stworzyć middleware, który uniemożliwia dostęp do grupy tras każdemu użytkownikowi, który nie jest administratorem.

> Zalecamy stworzenie folderu `Middleware` wewnątrz katalogu `Sources/App`, aby utrzymać porządek w kodzie

Middleware to typy zgodne z protokołem `Middleware` lub `AsyncMiddleware` Vapor. Są one wstawiane do łańcucha responderów i mogą uzyskiwać dostęp do zapytania oraz je modyfikować, zanim dotrze ono do handlera trasy, a także uzyskiwać dostęp do odpowiedzi oraz ją modyfikować, zanim zostanie ona zwrócona.

Korzystając z wyżej wspomnianego przykładu, utwórz middleware blokujący dostęp użytkownikowi, jeśli nie jest on administratorem:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

Lub jeśli używasz `async`/`await`, możesz napisać:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

Jeśli chcesz zmodyfikować odpowiedź, na przykład aby dodać niestandardowy nagłówek, możesz do tego również użyć middleware. Middleware może poczekać, aż odpowiedź zostanie odebrana z łańcucha responderów, i ją zmodyfikować:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

Lub jeśli używasz `async`/`await`, możesz napisać:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

`FileMiddleware` umożliwia serwowanie plików z folderu Public twojego projektu do klienta. Możesz w nim umieścić pliki statyczne, takie jak arkusze stylów czy obrazy bitmapowe.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Po zarejestrowaniu `FileMiddleware`, plik taki jak `Public/images/logo.png` może zostać podlinkowany w szablonie Leaf jako `<img src="/images/logo.png"/>`.

Jeśli twój serwer znajduje się w projekcie Xcode, takim jak aplikacja na iOS, użyj zamiast tego:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Upewnij się też, że w Xcode używasz odniesień do folderów (Folder References) zamiast grup (Groups), aby zachować strukturę folderów w zasobach po zbudowaniu aplikacji.

## CORS Middleware

Cross-origin resource sharing (CORS) to mechanizm, który pozwala na to, aby ograniczone zasoby na stronie internetowej mogły być żądane z innej domeny niż ta, z której pochodził pierwotny zasób. REST API zbudowane w Vapor będą wymagały polityki CORS, aby bezpiecznie zwracać odpowiedzi do nowoczesnych przeglądarek internetowych.

Przykładowa konfiguracja mogłaby wyglądać mniej więcej tak:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors middleware should come before default error middleware using `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Ponieważ zgłoszone błędy są natychmiast zwracane do klienta, `CORSMiddleware` musi znajdować się _przed_ `ErrorMiddleware`. W przeciwnym razie odpowiedź błędu HTTP zostanie zwrócona bez nagłówków CORS i nie będzie mogła zostać odczytana przez przeglądarkę.
