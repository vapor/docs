# Client HTTP

L'API Client de Vapor vous permet de faire des appels HTTP vers des ressources externes. Elle repose sur le composant [async-http-client](https://github.com/swift-server/async-http-client) et s'intègre à l'API de [contenu](content.md) vue au chapitre précédent.

## Vue d'ensemble

Vous avez accès au client par défaut via l'objet `Application`, ou depuis un gestionnaire de requête via l'objet `Request`.

```swift
app.client // Client

app.get("test") { req in
    req.client // Client
}
```

Le client proposé sur l'objet Application sert surtout pour faire des requêtes lors de la configuration (au démarrage de votre application). Si vous souhaitez faire des requêtes HTTP depuis un gestionnaire de requête, utilisez systématiquement le client de l'objet Request.

### Méthodes

Pour exécuter une requête `GET`, passez l'URL que vous souhaitez joindre en paramètre de la méthode `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Chaque verbe HTTP possède sa méthode associée, comme `get`, `post`, et `delete`. La réponse reçue par le client est retournée en tant que valeur de type future, et contient le statut HTTP, les entêtes, ainsi que le corps.

### Contenu

L'API de [contenu](content.md) de Vapor est disponible pour gérer les données du client aussi bien dans les requêtes que les réponses. Pour encoder du contenu, une QueryString, ou ajouter des entêtes à la requête, utilisez la Closure `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
    // Encodage de la QueryString à ajouter à l'URL.
    try req.query.encode(["q": "test"])

    // Encodage en JSON du corps de la requête.
    try req.content.encode(["hello": "world"])
    
    // Ajout de l'entête d'authentification/autorisation.
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Gestion de la réponse.
```

Vous pouvez également décoder le corps de la réponse grâce à `Content` :

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Si vous utilisez les types futures, vous pouvez utiliser `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
    try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
    // Utilisation du JSON ici.
}
```

## Configuration

Vous pouvez configurer le client HTTP sous-jacent via l'objet Application.

```swift
// Désactive le suivi automatique des redirections.
app.http.client.configuration.redirectConfiguration = .disallow
```

Veuillez noter que la configuration du client par défaut doit être faite _avant_ sa première utilisation.


