# Middleware

Un middleware est une chaîne logique entre le client et un gestionnaire de route (route handler) de Vapor. Il vous permet d'effectuer des opérations sur les requêtes entrantes avant qu'elles n'atteignent le gestionnaire de route, et sur les réponses sortantes avant qu'elles ne soient envoyées au client.

## Configuration

Un middleware peut être enregistré globalement (sur chaque route) dans `configure(_:)` en utilisant `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

Vous pouvez également ajouter un middleware à des routes individuelles en utilisant des groupes de routes.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
    // Cette requête est passée par MyMiddleware.
}
```

### Ordre

L'ordre dans lequel les middlewares sont ajoutés est important. Les requêtes entrant dans votre application traverseront les middlewares dans l'ordre où ils ont été ajoutés. Les réponses quittant votre application repasseront par les middlewares dans l'ordre inverse. Les middlewares spécifiques à une route s'exécutent toujours après les middlewares de l'application. Prenez l'exemple suivant :

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
    $0.get("hello") { req in
        "Hello, middleware."
    }
}
```

Une requête vers `GET /hello` visitera les middlewares dans l'ordre suivant :

```
Request → A → B → C → Handler → C → B → A → Response
```

Les middlewares peuvent également être _préfixés_ (prepended), ce qui est utile lorsque vous souhaitez ajouter un middleware _avant_ les middlewares par défaut que vapor ajoute automatiquement :

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Créer un middleware

Vapor est fourni avec quelques middlewares utiles, mais vous pourriez avoir besoin de créer le vôtre en fonction des exigences de votre application. Par exemple, vous pourriez créer un middleware qui empêche tout utilisateur non-administrateur d'accéder à un groupe de routes.

> Nous recommandons de créer un dossier `Middleware` dans votre répertoire `Sources/App` afin de garder votre code organisé

Les middlewares sont des types qui se conforment au protocole `Middleware` ou `AsyncMiddleware` de Vapor. Ils sont insérés dans la chaîne de réponse (responder chain) et peuvent accéder à une requête et la manipuler avant qu'elle n'atteigne un gestionnaire de route, ainsi qu'accéder à une réponse et la manipuler avant qu'elle ne soit retournée.

En reprenant l'exemple mentionné ci-dessus, créez un middleware pour bloquer l'accès à l'utilisateur s'il n'est pas administrateur :

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

Ou, si vous utilisez `async`/`await`, vous pouvez écrire :

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

Si vous souhaitez modifier la réponse, par exemple pour ajouter un en-tête personnalisé, vous pouvez également utiliser un middleware pour cela. Les middlewares peuvent attendre que la réponse soit reçue de la chaîne de réponse et la manipuler :

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

Ou, si vous utilisez `async`/`await`, vous pouvez écrire :

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

## Middleware de fichiers

`FileMiddleware` permet de servir au client des ressources situées dans le dossier Public de votre projet. Vous pourriez y inclure des fichiers statiques comme des feuilles de style ou des images bitmap.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Une fois `FileMiddleware` enregistré, un fichier comme `Public/images/logo.png` peut être référencé depuis un template Leaf via `<img src="/images/logo.png"/>`.

Si votre serveur est contenu dans un projet Xcode, comme une application iOS, utilisez plutôt ceci :

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Veillez également à utiliser des Folder References plutôt que des Groups dans Xcode afin de conserver la structure des dossiers dans les ressources après la compilation de l'application.

## CORS Middleware

Le partage des ressources entre origines multiples (Cross-origin resource sharing, ou CORS) est un mécanisme qui permet de demander des ressources restreintes d'une page web depuis un autre domaine que celui à partir duquel la première ressource a été servie. Les API REST construites avec Vapor nécessiteront une politique CORS afin de retourner en toute sécurité des requêtes aux navigateurs web modernes.

Un exemple de configuration pourrait ressembler à ceci :

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// le middleware cors doit précéder le middleware d'erreur par défaut en utilisant `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Étant donné que les erreurs levées sont immédiatement retournées au client, le `CORSMiddleware` doit être listé _avant_ l'`ErrorMiddleware`. Sinon, la réponse d'erreur HTTP sera retournée sans les en-têtes CORS, et ne pourra pas être lue par le navigateur.
