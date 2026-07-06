# Middleware

Les middlewares sont des composants formant une chaîne de logique entre le client et un gestionnaire de route Vapor. Ils vous permettent d'exécuter des traitements sur les requêtes entrantes avant qu'elles n'atteignent leur contrôleur, et sur les réponses sortantes avant qu'elles ne partent vers le client.

## Configuration

Un middleware peut s'enregistrer au niveau global (sur toutes les routes) dans `configure(_:)` via `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

Vous pouvez aussi ajouter des middlewares sur des routes au cas par cas en utilisant les groupes de routes.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
    // Cette requête a traversé MyMiddleware.
}
```

### Ordre

L'ordre dans lequel sont ajoutés les middlewares est important. Les requêtes entrant dans votre application traverseront la chaîne des middlewares dans l'ordre de leur ajout. Les réponses quittant votre application traverseront cette chaîne dans l'ordre inverse. Les middlewares appliqués au niveau des routes sont toujours invoqués après ceux appliqués au niveau de l'application. Prenez l'exemple suivant :

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
    $0.get("hello") { req in
        "Hello, middleware."
    }
}
```

Une requête sur `GET /hello` traversera les middlewares dans l'ordre suivant :

```
Requête → A → B → C → Closure de route → C → B → A → Réponse
```

Les middlewares peuvent aussi être ajoutés _au début_ de la chaîne, ce qui est pratique quand vous voulez en ajouter _avant_ ceux par défaut que Vapor ajoute automatiquement :

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Créer un middleware

Vapor est livré avec quelques middlewares utiles, mais vous aurez peut-être à en créer pour les besoins de votre application. Vous pourriez par exemple créer un middleware qui empêche les utilisateurs ne disposant pas de droits d'administration d'accéder à un groupe de routes donné.

> Nous recommandons de créer un dossier `Middleware` dans votre répertoire `Sources/App` pour garder votre code organisé.

Les middlewares sont des types qui se conforment à un des protocoles `Middleware` ou `AsyncMiddleware` de Vapor. Ils sont placés en file avant le contrôleur et peuvent accéder aux requêtes et les manipuler avant qu'elles ne l'atteignent, et peuvent également accéder aux réponses et les manipuler avant qu'elles ne soient renvoyées.

En reprenant l'exemple mentionné ci-dessus, créons un middleware qui bloque l'utilisateur s'il n'est pas administrateur :

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

Ou avec la syntaxe `async`/`await` :

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

Si vous souhaitez modifier la réponse, par exemple pour ajouter une entête personnalisée, vous pouvez aussi utiliser un middleware. Les middlewares peuvent attendre que la requête atteigne le maillon suivant de la chaîne (middleware ou contrôleur) pour recevoir la réponse et la traiter :

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

Ou avec la syntaxe `async`/`await` :

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

`FileMiddleware` permet d'exposer à vos clients des fichiers présents dans le dossier Public de votre projet. C'est ici que vous placeriez vos fichiers statiques comme du JavaScript, des feuilles de style ou images bitmap.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Une fois que `FileMiddleware` est enregistré, un fichier tel que `Public/images/logo.png` peut être ciblé depuis un template Leaf comme ceci : `<img src="/images/logo.png"/>`.

Si votre server est contenu dans un projet Xcode, comme une application iOS, utilisez plutôt ceci :

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Assurez-vous aussi d'utiliser des références de dossiers plutôt que des groupes dans Xcode pour conserver l'arborescence des dossiers dans vos ressources après la compilation de l'application.

## CORS Middleware

Cross-Origin Resource Sharing (CORS) est un mécanisme permettant à des ressources privées d'une page web d'être requêtées depuis un domaine situé en dehors de celui qui les expose. Les API REST construites avec Vapor nécessiteront une politique CORS pour répondre de façon sécurisée aux navigateurs web modernes.

Un exemple de configuration pourrait être :

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// Le middleware CORS devrait se placer avant le middleware de gestion des erreurs par défaut via `at: .beginning`.
app.middleware.use(cors, at: .beginning)
```

Puisque les erreurs levées sont immédiatement retournées au client, notre `CORSMiddleware` doit être placé _avant_ `ErrorMiddleware`. Autrement, la réponse d'erreur HTTP serait retournée sans entêtes CORS, qui ne pourraient donc pas être lues par le navigateur.
