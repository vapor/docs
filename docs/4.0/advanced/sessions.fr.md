# Sessions

Les sessions vous permettent de conserver les données utilisateur entre plusieurs requêtes consécutives. Les sessions marchent grâce à la création d'un cookie unique retourné avec la réponse HTTP au moment de leur initialisation. Les navigateurs détectent automatiquement ce cookie et l'ajoutent aux requêtes suivantes. Ce mécanisme permet à Vapor de restaurer automatiquement la session spécifique de l'utilisateur dans votre route. 

Les sessions sont adaptées pour des applications web front-end construites avec Vapor comme fournisseur direct de HTML aux navigateurs. Pour des APIs, nous recommandons d'utiliser une [authentification sans état basée sur un jeton](../security/authentication.md) pour conserver les données utilisateur entre requêtes consécutives.

## Configuration

Pour utiliser des sessions sur une route, la requête doit traverser le `SessionsMiddleware`. Le moyen le plus simple pour le faire est d'ajouter ce middleware sur la globalité de l'application. Nous recommandons que vous l'ajoutiez après avoir déclaré votre fabrique de cookies. Cette recommandation est motivée par le fait que les sessions sont des struct, qui sont un type passé par valeur, et non un type passé par référence. Puisqu'il s'agit d'un type passé par valeur, celle-ci doit être définie avant d'être utilisée par `SessionsMiddleware`.

```swift
app.middleware.use(app.sessions.middleware)
```

Si seulement certaines de vos routes utilisent les sessions, vous pouvez aussi ajouter le `SessionsMiddleware` uniquement à ce groupe.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

Le cookie HTTP généré par les sessions peut être configuré dans `app.sessions.configuration`. Vous pouvez modifier le nom du cookie et déclarer une fonction personnalisée pour générer les valeurs de cookies.

```swift
// Changement du nom de cookie en "foo".
app.sessions.configuration.cookieName = "foo"

// Configure la création de valeur des cookies.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

Par défaut, Vapor utilisera `vapor_session` comme nom de cookie.

## Pilotes

Les pilotes de session ont la responsabilité de stoquer et récupérer les données de session via un identifiant. Vous pouvez créer des pilotes personnalisés en vous conformant au protocole `SessionDriver`.

!!! Attention
    Le pilote de session doit être configuré _avant_ l'ajout de `app.sessions.middleware` à votre application.

### En mémoire

Vapor stoque les sessions en mémoire par défaut. Aucune configuration n'est nécessaire pour les sessions en mémoire, et elles ne sont pas conservées entre les redémarrages de votre application, ce qui les rend idéales pour les tests. Pour activer les sessions en mémoire, utilisez `.memory` :

```swift
app.sessions.use(.memory)
```

Pour des usages en production, veuillez regarder les autres pilotes de session qui utilisent des bases de données pour stoquer et partager les sessions entre plusieurs instances de votre application.

### Fluent

Fluent permet de stoquer les données de session dans la base de données de votre application. Cette section suppose que vous avez [configuré Fluent](../fluent/overview.md) et que vous pouvez vous connecter à une base de données. La première étape consiste à activer le pilote de sessions Fluent.

```swift
import Fluent

app.sessions.use(.fluent)
```

Ceci configurera les sessions pour qu'elles utilisent la base de données par défaut de votre application. Pour préciser une base de données spécifique, passez en paramètre l'identifiant de votre base :

```swift
app.sessions.use(.fluent(.sqlite))
```

Enfin, ajoutez la migration de `SessionRecord` aux migrations de votre base de données. Ceci préparera votre base de données au stoquage des données de session dans le schéma `_fluent_sessions`.

```swift
app.migrations.add(SessionRecord.migration)
```

Assurez-vous d'exécuter les migrations de votre application après avoir ajouté cette dernière. Les sessions seront désormais stoquées dans la base de données de votre application, ce qui assure leur persistance entre les redémarrages ainsi que leur disponibilité pour les différentes instances de votre application.

### Redis

Redis permet le stoquage des données de session dans votre instance Redis configurée. Cette section suppose que vous avez [configuré Redis](../redis/overview.md) et que vous pouvez envoyer des commandes à l'instance Redis.

Pour utiliser Redis pour les sessions, indiquez-le dans la configuration de votre application :

```swift
import Redis

app.sessions.use(.redis)
```

Ceci configurera les sessions pour qu'elles utilisent le pilote de sessions Redis avec son comportement par défaut.

!!! A lire également
    Voir [Redis &rarr; Sessions](../redis/sessions.md) pour des informations plus détaillées sur Redis et les sessions.

## Données de session

Maintenant que les sessions sont configurées, vous êtes prêt à persister les données entre les requêtes. De nouvelles sessions sont automatiquement initialisées lorsque des données sont ajoutées à `req.session`. Le contrôleur ci-dessous reçoit le paramètre dynamique de la route et ajoute sa valeur à `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Utilisez la requête suivante pour initialiser une session comportant le nom Vapor.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Vous devriez recevoir une réponse semblable à celle-ci :

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Remarquez l'entête `set-cookie` qui a été automatiquement ajoutée à la réponse après que nous ayons ajouté des données à `req.session`. Inclure ce cookie aux requêtes suivantes permettra l'accès aux données de session.

Ajoutez le contrôleur suivant pour accéder à la valeur name stoquée en session.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Utilisez la requête suivante pour accéder à cette route tout en incluant la valeur de cookie obtenue par la réponse précédente :

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Vous devriez voir le nom Vapor retourné en réponse. Vous pouvez ajouter ou supprimer des données de session comme bon vous semble. Les données de session seront synchronisées avec le pilote de session automatiquement avant l'émission de la réponse HTTP. 

Pour clore une session, utilisez `req.session.destroy`. Ceci supprimera les données du pilote de session et invalidera le cookie de session. 

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
