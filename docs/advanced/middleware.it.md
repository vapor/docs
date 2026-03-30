# Middleware

Il middleware è una catena logica tra il client e un gestore di route di Vapor. Ti permette di eseguire operazioni sulle request in arrivo prima che raggiungano il gestore di route e sulle response in uscita prima che vengano inviate al client.

## Configurazione

Il middleware può essere registrato globalmente (su ogni route) in `configure(_:)` usando `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

Puoi anche aggiungere middleware a singole route usando i gruppi di route.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// Questa request è passata attraverso MyMiddleware.
}
```

### Ordine

L'ordine in cui i middleware vengono aggiunti è importante. Le request in arrivo alla tua applicazione passeranno attraverso i middleware nell'ordine in cui sono stati aggiunti. Le response in uscita dalla tua applicazione torneranno indietro attraverso i middleware in ordine inverso. Il middleware specifico per le route viene eseguito sempre dopo il middleware dell'applicazione. Considera il seguente esempio:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

Una richiesta a `GET /hello` visiterà i middleware nel seguente ordine:

```
Request → A → B → C → Handler → C → B → A → Response
```

I middleware possono anche essere _prepended_ (aggiunti in testa), il che è utile quando vuoi aggiungere un middleware _prima_ del middleware predefinito aggiunto automaticamente da Vapor:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Creare un Middleware

Vapor include alcuni middleware utili, ma potresti dover crearne di tuoi in base ai requisiti della tua applicazione. Ad esempio, potresti creare un middleware che impedisce a qualsiasi utente non amministratore di accedere a un gruppo di route.

> Ti raccomandiamo di creare una cartella `Middleware` all'interno della directory `Sources/App` per mantenere il codice organizzato

I middleware sono tipi conformi al protocollo `Middleware` o `AsyncMiddleware` di Vapor. Vengono inseriti nella catena di risposta e possono accedere e manipolare una request prima che raggiunga un gestore di route e accedere e manipolare una response prima che venga restituita.

Usando l'esempio menzionato sopra, crea un middleware per bloccare l'accesso all'utente se non è un amministratore:

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

Oppure se usi `async`/`await` puoi scrivere:

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

Se vuoi modificare la risposta, ad esempio per aggiungere un header personalizzato, puoi usare un middleware anche per questo. I middleware possono attendere che la risposta venga ricevuta dalla catena di risposta e manipolarla:

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

Oppure se usi `async`/`await` puoi scrivere:

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

`FileMiddleware` abilita la distribuzione degli asset dalla cartella Public del tuo progetto al client. Qui potresti includere file statici come fogli di stile o immagini bitmap.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Una volta registrato `FileMiddleware`, un file come `Public/images/logo.png` può essere collegato da un template Leaf come `<img src="/images/logo.png"/>`.

Se il tuo server è contenuto in un progetto Xcode, come un'app iOS, usa invece questo:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Assicurati anche di usare Folder References invece di Groups in Xcode per mantenere la struttura delle cartelle nelle risorse dopo la compilazione dell'applicazione.

## CORS Middleware

Il Cross-origin resource sharing (CORS) è un meccanismo che consente alle risorse con restrizioni su una pagina web di essere richieste da un altro dominio diverso da quello da cui è stata servita la prima risorsa. Le API REST create in Vapor richiederanno una policy CORS per restituire in modo sicuro le richieste ai moderni browser web.

Un esempio di configurazione potrebbe essere simile a questo:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// il CORS middleware deve venire prima del middleware di errore predefinito usando `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Poiché gli errori lanciati vengono restituiti immediatamente al client, il `CORSMiddleware` deve essere elencato _prima_ dell'`ErrorMiddleware`. Altrimenti, la risposta di errore HTTP verrà restituita senza gli header CORS e non potrà essere letta dal browser.
