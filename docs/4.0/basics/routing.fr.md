# Le routage

Le routage consiste à trouver le bon contrôleur pour gérer une requête entrante. Le coeur du routage de Vapor est géré par un routeur hautes performances à algorithme trie, fourni par [RoutingKit](https://github.com/vapor/routing-kit).

## Vue d'ensemble 

Pour comprendre le fonctionnement du routage dans Vapor, vous devriez d'abord comprendre quelques bases des requêtes HTTP. Observez les quelques exemples de requêtes suivants.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Il s'agit d'une simple requête HTTP `GET` sur l'URL `/hello/vapor`. C'est le genre de requête que ferait votre navigateur si vous lui indiquiez cet URL :

```
http://vapor.codes/hello/vapor
```

### Méthode HTTP

La première partie d'une requête est la méthode HTTP. `GET` est la méthode HTTP la plus courante, mais vous serez également amené à en utiliser quelques autres. Ces méthodes HTTP sont souvent associées aux  sémantiques [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|Méthode HTTP|Correspondance CRUD|
|-|-|
|`GET`|Read|
|`POST`|Create|
|`PUT`|Replace|
|`PATCH`|Update|
|`DELETE`|Delete|

### Chemin de la requête

Se situant juste après la méthode HTTP se trouve l'URI de la requête. Il consiste en un chemin qui commence par un `/` et facultativement complétée par une QueryString commençant par un `?`. La méthode HTTP et le chemin de la requête sont les deux éléments utilisés par Vapor pour router les requêtes entrantes.

A la suite de l'URI se trouve la version HTTP, suivie de 0 ou n entêtes, et enfin le corps de la requête. Dans ce cas précis, concernant une requête `GET`, aucun corps de requête n'est présent. 

### Méthodes du router

Voyons comment Vapor pourrait traiter la requête définie précédemment. 

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

Toutes les méthodes HTTP courantes sont exposées en tant que méthodes de l'objet `Application`. Elles acceptent une ou plusieurs chaînes de caractères, qui représentent le chemin de la requête séparé par des `/`. 

Notez que vous pouvez également utiliser la syntaxe alternative `on` suivie de la méthode HTTP à utiliser :

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Une fois la route enregistrée, la requête HTTP d'exemple recevra pour résultat la réponse HTTP suivante :

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Paramètres de route

Maintenant que nous avons correctement routé une requête en fonction de sa méthode HTTP et de son chemin, essayons de rendre ce chemin dynamique. Remarquez que le nom "vapor" est codé en dur à la fois dans le chemin et la réponse. Rendons cela dynamique pour que vous puissiez joindre `/hello/<un nom quelconque>` et obtenir une réponse.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

En utilisant un composant de chemin prefixé du caractère `:`, nous indiquons au routeur qu'il s'agit d'un composant dynamique. Tout chaîne de caractère située à cet endroit précis sera donc mis en correspondance avec cette route. Nous pourrons alors utiliser `req.parameters` pour accéder à la valeur de la chaîne d'entrée.

Si vous soumettez à nouveau la requête d'exemple, vous obtiendrez toujours une réponse disant hello à vapor. Cependant, vous pouvez désormais indiquer n'importe quel nom après `/hello/` et constater qu'il sera retourné dans la réponse.

Essayons avec `/hello/swift` :

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

Maintenant que les bases sont couvertes, consultez les sections détaillées pour en apprendre plus sur les paramètres, groupes, and autres notions complémentaires.

## Routes

Un objet Route spécifie quel gestionnaire de requête (ou contrôleur) sera associé à une méthode HTTP et un chemin URI donnés. Il peut également contenir des méta-données supplémentaires.

### Méthodes

Vous pouvez directement enregistrer de nouvelles routes sur votre objet `Application` en utilisant les différentes méthodes HTTP exposées. 

```swift
// Répond à GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

Les gestionnaires de requêtes associés aux routes peuvent retourner n'importe quelle donnée, tant qu'elle implémente le protocole `ResponseEncodable`. Cela inclue `Content`, des  Closures `async`, et tout `EventLoopFuture` dont la valeur future implémente `ResponseEncodable`.

Vous pouvez déclarer le type de retour d'une route avec `-> T` avant le `in`. Cela pourra vous servir dans les cas où le compilateur ne peut pas déterminer le type de retour.

```swift
app.get("foo") { req -> String in
    return "bar"
}
```

Voici les méthodes exposées par l'objet Application pour faciliter l'enregistrement de vos routes :

- `get`
- `post`
- `patch`
- `put`
- `delete`

En plus de ces méthodes dites helper, vous pouvez utiliser la méthode `on` qui accepte un verbe HTTP en paramètre. 

```swift
// Répond à OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
    ...
}
```

### Composants de chemin

Chaque méthode de déclaration de route accepte en paramètre une liste variadique de type `PathComponent`. Ce type s'exprime en chaîne de caractères littérale et peut couvrir quatre cas :

- Constant (`foo`)
- Parameter (`:foo`)
- Anything (`*`)
- Catchall (`**`)

#### Constant

Il s'agit d'un composant fixe de la route. Seules les requêtes ayant une correspondance exacte avec ce composant à cette position pourront être routées. 

```swift
// Répond à GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

#### Parameter

Il s'agit d'un composant dynamique de la route. Toute chaîne à cet endroit sera autorisée. Un composant de chemin paramétrable est défini par le préfixe deux-points `:`. La chaîne qui suit ce `:` servira de nom de paramètre. Vous pourrez ensuite utiliser ce nom pour récupérer la valeur du paramètre renseigné par la requête.

```swift
// Répond à GET /foo/bar/baz
// Répond à GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
    ...
}
```

#### Anything

Similaire au composant dynamique Parameter, la différence est ici que la valeur reçue n'est pas conservée. Ce composant est simplement déclaré par un astérisque `*`. 

```swift
// Répond à GET /foo/bar/baz
// Répond à GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
    ...
}
```

#### Catchall

Ce composant de route dynamique pourra créer une correspondance avec un composant de chemin, ou plus. Il est simplement déclaré par un double astérisque `**`. Toute chaîne présente à partir de cette position (dont les suivantes) seront mise en correspondance avec la requête reçue. 

```swift
// Répond à GET /foo/bar
// Répond à GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### Lire les paramètres dynamiques

Lorsque vous utilisez un composant de chemin de type Parameter (préfixé par deux-points `:`), la valeur de l'URI à cette position sera stoquée dans `req.parameters`. Vous pouvez utiliser le nom que vous avez défini pour ce composant du chemin afin d'accéder à la valeur. 

```swift
// Répond à GET /hello/foo
// Répond à GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! Note
    Ici, nous pouvons être sûrs que `req.parameters.get` ne retournera jamais `nil` car le chemin de notre route comporte la valeur `:name`. Cependant, si vous tentez d'accéder aux paramètres de routes depuis un middleware ou dans du code déclenché par différentes routes, vous devrez gérer le cas éventuel où la valeur retournée sera `nil`.

!!! Note
    Si vous souhaitez récupérer des paramètres de la QueryString, i.e. `/hello/?name=foo` vous devrez utiliser les API Content de Vapor pour gérer les données qui sont url-encodées. Voir la [rubrique `Content`](content.md) pour plus d'information.

`req.parameters.get` supporte aussi le cast automatique vers les types compatibles avec le protocole `LosslessStringConvertible` :

```swift
// Répond à GET /number/42
// Répond à GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
    guard let int = req.parameters.get("x", as: Int.self) else {
        throw Abort(.badRequest)
    }
    return "\(int) is a great number"
}
```

Les valeurs des URI qui ont été routées avec un Catchall (`**`) seront stoquées dans `req.parameters` en tant que `[String]`. Vous pouvez accéder à ces composants par `req.parameters.getCatchall`. 

```swift
// Répond à GET /hello/foo
// Répond à GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body Streaming

Lorsque vous déclarez une route avec la méthode `on`, vous pouvez définir comment le corps de la requête doit être géré. Par défaut, les corps de requêtes sont mis en mémoire avant d'invoquer votre gestionnaire de requête. C'est utile, car cela permet de décoder le contenu des requêtes de façon synchrone, même si votre application lit les requêtes entrantes de façon asynchrone. 

Par défaut, Vapor limite la récupération du corps de la requête à une taille de 16Ko. Vous pouvez configurer cette valeur sur `app.routes`.
Attention aux unités, en Anglais, 1 Byte = 1 Octet = 8 bits.

```swift
// Augmente la limite de taille de lecture du corps de la requête à 500ko
app.routes.defaultMaxBodySize = "500kb"
```

Si les données du corps de requête en cours de lecture dépassent la limite configurée, une erreur `413 Payload Too Large` sera levée. 

Pour configurer la stratégie de lecture du corps de requête au niveau d'une route individuelle, utilisez le paramètre `body`.

```swift
// Lira le corps des requêtes pour les mettre en mémoire (jusqu'à une limite de 1mo) avant d'appeler cette route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Gestion de la requête. 
}
```

Si vous spécifiez la valeur de l'argument `maxSize` à `collect`, cette valeur sera choisie pour cette route, peu importe la valeur que vous aurez définie au niveau global de l'application. Si vous souhaitez utiliser la valeur par défaut définie sur l'application, omettez simplement l'argument`maxSize`. 

Pour des requêtes imposantes, tels que des mises en ligne de fichiers, récupérer le corps de la requête dans un buffer peut mettre à mal la mémoire disponible de votre système. Pour éviter la mise en mémoire du corps de la requête, utilisez la stratégie `stream`.

```swift
// Le corps de requête ne sera pas mis en mémoire.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Lorsque le corps de la requête est mis en flux, `req.body.data` vaudra `nil`. Vous devrez utiliser `req.body.drain` pour traiter chaque extrait de corps au fur et à mesure qu'il arrive à votre route.

### Routage insensible à la casse

Le comportement par défaut du routage est à la fois sensible à la casse et la préservant. Les composants de chemin de type `Constant` peuvent aussi être gérés de façon à les rendre insensibles à la casse (toujours en la préservant) pour les besoins du routage; pour activer ce comportement, ajoutez cette configuration avant le démarrage de votre application :
```swift
app.routes.caseInsensitive = true
```
Aucun changement n'est appliqué à la requête entrante; les gestionnaires de requêtes recevront les composants du chemin inaltérés.


### Lister les Routes

Vous pouvez accéder aux routes de votre application par le service `Routes`, ou en utilisant `app.routes`. 

```swift
print(app.routes.all) // [Route]
```

Vapor fournit aussi une commande `routes` qui affiche toutes les routes enregistrées sous forme de tableau ASCII. 

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### Meta-données

Toutes les méthodes d'enregistrement de route retournent l'objet `Route` instancié. Cela vous permet d'ajouter des méta-données au dictionnaire `userInfo` de la route. Des méthodes par défaut sont proposées, comme pour l'ajout d'une description.

```swift
app.get("hello", ":name") { req in
    ...
}.description("says hello")
```

## Groupes de routes

Le groupement de routes vous permet de mettre en commun les routes qui partagent un préfixe dans leur chemin, ou un middleware spécifique. Le groupement supporte les syntaxes builder et closure.

Toutes les méthodes de regroupement retournent un objet `RouteBuilder` ce qui vous donne la souplesse de mélanger vos déclarations de groupes imbriqués à volonté, avec autant de méthodes de déclaration de routes que vous le souhaitez.

### Préfixe de chemin

Les groupes de routes à préfixe vous permettent d'ajouter en une seule fois un ou plusieurs composants de chemin en début de chaque route du groupe. 

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Chaque composant de chemin que vous pouvez passer aux méthodes telles que `get` ou `post` peut aussi être passé à  `grouped`. Il existe également une syntaxe alternative, basé sur les Closures.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

Imbriquer des groupes de routes à préfixes vous permet de définir des API CRUD de façon concise.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### Middleware

En plus des composants de préfixes, vous pouvez ajouter des middlewares à vos groupes. 

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```

C'est particulièrement utile pour protéger des sous-groupes de vos routes avec des middlewares d'authentification. 

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Redirections

Les redirections sont utiles dans différents scénarios, comme faire suivre de vieux URLs vers des plus récents pour le SEO, rediriger des utilisateurs non authentifiés vers un formulaire de connexion, ou assurer une compatibilité descendante avec la nouvelle version de votre API.

Pour rediriger une requête, utilisez :

```swift
req.redirect(to: "/some/new/path")
```

Vous pouvez également personnaliser le type de redirection, comme une redirection permanente par exemple (pour que votre SEO soit mis à jour correctement) :

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

Les différents types proposés par `Redirect` sont:

* `.permanent` - retourne **301 Permanent**
* `.normal` - retourne **303 see other**. C'est le comportement par défaut de Vapor, qui indique au client de suivre la redirection avec une requête **GET**.
* `.temporary` - retourne **307 Temporary**. Cela indique au client qu'il doit conserver la méthode HTTP utilisée dans sa requête.

> Pour choisir la bonne redirection, référez-vous à [la liste complète](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)
