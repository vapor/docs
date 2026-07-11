# Sessions

Les sessions vous permettent de persister les données d'un utilisateur entre plusieurs requêtes. Les sessions fonctionnent en créant et en renvoyant un cookie unique accompagnant la réponse HTTP lorsqu'une nouvelle session est initialisée. Les navigateurs détecteront automatiquement ce cookie et l'incluront dans les requêtes futures. Cela permet à Vapor de restaurer automatiquement la session d'un utilisateur spécifique dans votre gestionnaire de requête.

Les sessions sont idéales pour les applications web front-end construites avec Vapor qui servent directement du HTML aux navigateurs web. Pour les API, nous recommandons d'utiliser une [authentification par jeton](../security/authentication.md) sans état pour persister les données utilisateur entre les requêtes.

## Configuration

Pour utiliser les sessions dans une route, la requête doit passer par le `SessionsMiddleware`. Le moyen le plus simple d'y parvenir est d'ajouter ce middleware globalement. Il est recommandé de l'ajouter après avoir déclaré la fabrique de cookies (cookie factory). En effet, `Sessions` est une struct, donc un type valeur, et non un type référence. Étant un type valeur, vous devez définir sa valeur avant d'utiliser `SessionsMiddleware`.

```swift
app.middleware.use(app.sessions.middleware)
```

Si seule une partie de vos routes utilise les sessions, vous pouvez à la place ajouter `SessionsMiddleware` à un groupe de routes.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

Le cookie HTTP généré par les sessions peut être configuré à l'aide de `app.sessions.configuration`. Vous pouvez modifier le nom du cookie et déclarer une fonction personnalisée pour générer les valeurs de cookie.

```swift
// Change the cookie name to "foo".
app.sessions.configuration.cookieName = "foo"

// Configures cookie value creation.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

Par défaut, Vapor utilisera `vapor_session` comme nom de cookie.

## Pilotes

Les pilotes de session sont responsables du stockage et de la récupération des données de session par identifiant. Vous pouvez créer des pilotes personnalisés en vous conformant au protocole `SessionDriver`.

!!! warning
    Le pilote de session doit être configuré _avant_ d'ajouter `app.sessions.middleware` à votre application.

### En mémoire

Vapor utilise par défaut des sessions en mémoire. Les sessions en mémoire ne nécessitent aucune configuration et ne persistent pas entre les lancements de l'application, ce qui les rend idéales pour les tests. Pour activer manuellement les sessions en mémoire, utilisez `.memory` :

```swift
app.sessions.use(.memory)
```

Pour des cas d'usage en production, examinez les autres pilotes de session qui utilisent des bases de données pour persister et partager les sessions entre plusieurs instances de votre application.

### Fluent

Fluent inclut une prise en charge du stockage des données de session dans la base de données de votre application. Cette section suppose que vous avez [configuré Fluent](../fluent/overview.md) et que vous pouvez vous connecter à une base de données. La première étape consiste à activer le pilote de sessions Fluent.

```swift
import Fluent

app.sessions.use(.fluent)
```

Cela configurera les sessions pour utiliser la base de données par défaut de l'application. Pour spécifier une base de données particulière, passez l'identifiant de cette base de données.

```swift
app.sessions.use(.fluent(.sqlite))
```

Enfin, ajoutez la migration de `SessionRecord` aux migrations de votre base de données. Cela préparera votre base de données pour le stockage des données de session dans le schéma `_fluent_sessions`.

```swift
app.migrations.add(SessionRecord.migration)
```

Assurez-vous d'exécuter les migrations de votre application après avoir ajouté la nouvelle migration. Les sessions seront désormais stockées dans la base de données de votre application, ce qui leur permet de persister entre les redémarrages et d'être partagées entre plusieurs instances de votre application.

### Redis

Redis prend en charge le stockage des données de session dans votre instance Redis configurée. Cette section suppose que vous avez [configuré Redis](../redis/overview.md) et que vous pouvez envoyer des commandes à l'instance Redis.

Pour utiliser Redis pour les sessions, sélectionnez-le lors de la configuration de votre application :

```swift
import Redis

app.sessions.use(.redis)
```

Cela configurera les sessions pour utiliser le pilote de sessions Redis avec le comportement par défaut.

!!! seealso
    Consultez [Redis &rarr; Sessions](../redis/sessions.md) pour des informations plus détaillées sur Redis et les sessions.

## Données de session

Maintenant que les sessions sont configurées, vous êtes prêt à persister des données entre les requêtes. De nouvelles sessions sont initialisées automatiquement lorsque des données sont ajoutées à `req.session`. L'exemple de gestionnaire de route ci-dessous accepte un paramètre de route dynamique et ajoute la valeur à `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Utilisez la requête suivante pour initialiser une session avec le nom Vapor.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Vous devriez recevoir une réponse similaire à la suivante :

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Remarquez que l'en-tête `set-cookie` a été ajouté automatiquement à la réponse après l'ajout de données à `req.session`. L'inclusion de ce cookie dans les requêtes suivantes permettra d'accéder aux données de session.

Ajoutez le gestionnaire de route suivant pour accéder à la valeur name depuis la session.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Utilisez la requête suivante pour accéder à cette route en veillant à transmettre la valeur du cookie provenant de la réponse précédente.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Vous devriez voir le nom Vapor retourné dans la réponse. Vous pouvez ajouter ou retirer des données de la session comme bon vous semble. Les données de session seront synchronisées automatiquement avec le pilote de session avant le renvoi de la réponse HTTP.

Pour terminer une session, utilisez `req.session.destroy`. Cela supprimera les données du pilote de session et invalidera le cookie de session.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
