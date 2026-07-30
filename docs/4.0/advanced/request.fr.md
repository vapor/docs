# Requête

L'objet [`Request`](https://api.vapor.codes/vapor/request) est passé à chaque [route](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Cet objet est la fenêtre principale vers le reste des fonctionnalités de Vapor. Il expose des APIs pour le [corps de la requête](../basics/content.md), [les paramètres query-string](../basics/content.md#querystring), un [logger](../basics/logging.md), un [client HTTP](../basics/client.md), un objet [Authenticator](../security/authentication.md), et bien plus. L'accès à ces fonctionnalités via la requête permet de conserver les calculs sur le bon event-loop et permet de les remplacer par des mocks pour les tests. Vous pouvez aussi ajouter vos propres [services](../advanced/services.md) à l'objet `Request` grâce à des extensions.

La documentation complète de l'API pour l'objet `Request` se trouve [ici](https://api.vapor.codes/vapor/request).

## Application

La propriété `Request.application` conserve une référence vers l'objet [`Application`](https://api.vapor.codes/vapor/application). Cet objet contient toutes les configurations et fonctionnalités principales de l'application. La plupart devraient uniquement être définis dans `configure.swift`, avant que l'application ne démarre complètement, et bon nombre des APIs bas niveau ne serviront pas pour la plupart des applications. Une des propriétés les plus utiles est `Application.eventLoopGroup`, qui peut servir à obtenir un `EventLoop` via la méthode `any()` pour les processus qui en ont besoin d'un nouveau. Elle contient aussi tout l'[`Environnement`](../basics/environment.md).

## Corps

Si vous voulez un accès direct au corps de la requête en tant qu'objet `ByteBuffer`, vous pouvez utiliser `Request.body.data`. Cela peut servir à la diffusion de données en streaming du corps de la requête vers un fichier (mais vous devriez plutôt utiliser la propriété [`fileio`](../advanced/files.md) de la requête pour cela) ou vers un autre client HTTP.

## Cookies

Bien que le cas d'usage le plus utile pour les cookies soit via les [sessions](../advanced/sessions.md#configuration) intégrées, vous pouvez également y accéder directement via `Request.cookies`.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Entêtes

Un objet `HTTPHeaders` de Swift NIO peut être obtenu via `Request.headers`. Il contient l'ensemble des entêtes envoyés avec la requête. Vous pouvez l'utiliser pour accéder à l'entête `Content-Type`, par exemple.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Vous trouverez une documentation plus complète sur l'objet `HTTPHeaders` [ici](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor ajoute plusieurs extensions à l'objet `HTTPHeaders` pour simplifier les cas d'usages d'entêtes les plus courants; une liste est disponible [ici](https://api.vapor.codes/vapor/niohttp1/httpheaders#instance-properties)

## Adresse IP

L'objet `SocketAddress` de Swift NIO qui représente le client est accessible via `Request.remoteAddress`, et peut servir pour de la journalisation ou de la limite de requête grâce à la représentation en chaîne de caractères accessible via `Request.remoteAddress.ipAddress`. La représentation de l'adresse IP du client peut être imprécise si l'application est derrière un reverse proxy. 

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Vous trouverez une documentation plus complète sur l'objet `SocketAddress` [ici](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
