# Request

L'objet [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) est transmis à chaque [gestionnaire de route](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

C'est la principale fenêtre ouvrant sur le reste des fonctionnalités de Vapor. Il contient des API pour le [corps de la requête](../basics/content.md), les [paramètres de requête](../basics/content.md#query), le [logger](../basics/logging.md), le [client HTTP](../basics/client.md), l'[Authenticator](../security/authentication.md), et plus encore. Accéder à ces fonctionnalités via la requête permet de garder le calcul sur la bonne boucle d'événements (event loop) et de le simuler (mock) pour les tests. Vous pouvez même ajouter vos propres [services](../advanced/services.md) à `Request` grâce à des extensions.

La documentation complète de l'API pour `Request` se trouve [ici](https://api.vapor.codes/vapor/documentation/vapor/request).

## Application

La propriété `Request.application` détient une référence vers l'[`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). Cet objet contient toute la configuration et les fonctionnalités essentielles de l'application. La majeure partie ne devrait être définie que dans `configure.swift`, avant que l'application ne démarre complètement, et de nombreuses API de plus bas niveau ne seront pas nécessaires dans la plupart des applications. L'une des propriétés les plus utiles est `Application.eventLoopGroup`, qui peut être utilisée pour obtenir un `EventLoop` pour les processus qui en ont besoin d'un nouveau via la méthode `any()`. Elle contient également l'[`Environment`](../basics/environment.md).

## Body

Si vous souhaitez accéder directement au corps de la requête en tant que `ByteBuffer`, vous pouvez utiliser `Request.body.data`. Cela peut être utilisé pour diffuser (streaming) des données du corps de la requête vers un fichier (bien que vous devriez plutôt utiliser la propriété [`fileio`](../advanced/files.md) de la requête pour cela) ou vers un autre client HTTP.

## Cookies

Bien que l'utilisation la plus utile des cookies passe par les [sessions](../advanced/sessions.md#configuration) intégrées, vous pouvez aussi accéder aux cookies directement via `Request.cookies`.

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

## Headers

Un objet `HTTPHeaders` est accessible via `Request.headers`. Il contient tous les en-têtes envoyés avec la requête. Il peut être utilisé pour accéder à l'en-tête `Content-Type`, par exemple.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Vous trouverez davantage de documentation sur `HTTPHeaders` [ici](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor ajoute également plusieurs extensions à `HTTPHeaders` pour faciliter le travail avec les en-têtes les plus couramment utilisés ; une liste est disponible [ici](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)

## Adresse IP

Le `SocketAddress` représentant le client est accessible via `Request.remoteAddress`, ce qui peut être utile pour la journalisation ou la limitation de débit (rate limiting) en utilisant la représentation sous forme de chaîne `Request.remoteAddress.ipAddress`. Elle peut ne pas représenter avec exactitude l'adresse IP du client si l'application se trouve derrière un reverse proxy.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Vous trouverez davantage de documentation sur `SocketAddress` [ici](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
