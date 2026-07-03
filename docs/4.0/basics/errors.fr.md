# Gestion des erreurs

Vapor se base sur le protocole `Error` de Swift pour sa gestion des erreurs. Les gestionnaires de routes peuvent soit utiliser `throw` pour lever une erreur, ou retourner un `EventLoopFuture` en échec. Lever ou retourner une `Error` de Swift renverra une réponse avec le statut HTTP `500` et l'erreur sera logguée. `AbortError` et `DebuggableError` peuvent être utilisées pour modifier la réponse et le log résultants. La gestion des erreurs est faite par l'objet `ErrorMiddleware`. Ce middleware est ajouté à l'application par défaut, et vous pouvez le remplacer par votre logique personnalisée si vous le souhaitez. 

## Abort

Vapor fournit une structure d'erreur par défaut nommée `Abort`. Cette structure se conforme à `AbortError` et `DebuggableError`. Vous pouvez l'initialiser avec un statut HTTP et raison d'échec facultative.

```swift
// Erreur 404, le message par défaut ("Not Found") est utilisé.
throw Abort(.notFound)

// Erreur 401, avec message personnalisé.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

Dans les anciennes situations asynchrones où il n'est pas possible d'utiliser `throw` et où vous devez retourner un `EventLoopFuture`, comme dans une Closure `flatMap`, vous pouvez retourner un futur échoué.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor fournit une extension pour aider à déballer des futurs avec valeurs optionnelles : `unwrap(or:)`. 

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Objet User non-optionnel passé à la Closure.
}
```

Si `User.find` retourne `nil`, le futur sera compromis avec l'erreur fournie. Autrement, `flatMap` se verra attribuer une valeur non-optionnelle. Si vous utilisez `async`/`await`, vous pouvez gérer les optionnels normalement :

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

Par défaut, toute `Error` Swift levée ou retournée par une Closure de route déclenchera une réponse `500 Internal Server Error`. Si compilé en mode debug, `ErrorMiddleware` comportera une description de l'erreur. Cette donnée est supprimée pour des raisons de sécurité lorsque le projet est compilé en mode release. 

Pour configurer le statut HTTP de réponse ou la raison d'une erreur en particulier, conformez-la au protocole `AbortError`. 

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

`ErrorMiddleware` utilise la méthode `Logger.report(error:)` pour logger les erreurs levées par vos routes. Cette méthode vérifie la conformance à des protocoles comme `CustomStringConvertible` et `LocalizedError` pour logger des messages intelligibles.

Pour personnaliser les logs d'erreurs, vous pouvez conformer vos erreurs à `DebuggableError`. Ce protocole comporte un certain nombre de propriétés utiles comme un identifiant unique, la source de l'erreur, ainsi que la stack trace. La plupart de ces propriétés sont optionnelles, ce qui facilite l'adoption de cette mise en conformité au protocole. 

Pour se conformer au mieux à `DebuggableError`, votre erreur devrait être une struct pour lui permettre de stoquer les informations de source et la stack trace si nécessaire. Vous trouverez ci-dessous un exemple de l'enum `MyError` sus-mentionnée, mise à jour pour utiliser une `struct` et capturer l'information de la source d'erreur.

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

`DebuggableError` comporte plusieurs autres propriétés comme `possibleCauses` et `suggestedFixes` que vous pouvez utiliser pour améliorer le débogage de vos erreurs. Observez la déclaration du protocole lui-même pour obtenir plus d'informations.

## Error Middleware

`ErrorMiddleware` est l'un des deux middlewares qui sont ajoutés à votre application par défaut. Ce middleware convertit les erreurs Swift levées ou retournées dans vos routes en réponses HTTP. Sans ce middleware, les erreurs levées causeraient la fermeture de la connexion, et aucune réponse ne serait retournée. 

Pour personnaliser la gestion des erreurs au-delà de ce que `AbortError` et `DebuggableError` permettent, vous pouvez remplacer `ErrorMiddleware` par votre propre logique personnalisée. Pour ce faire, commencez par enlever l'ErrorMiddleware par défaut en initialisant manuellement `app.middleware`. Puis, ajoutez votre propre middleware de gestion d'erreurs comme premier middleware sur votre application.

```swift
// Enlève tous les middlewares définis par défaut (puis ré-ajoute le log des routes)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Ajout du middleware personnalisé de gestion des erreurs.
app.middleware.use(MyErrorMiddleware())
```

Très peu de middlewares devraient être enregistrés _avant_ celui de gestion des erreurs. Une exception notable à cette règle, le `CORSMiddleware`.
