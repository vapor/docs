# Request

Das [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request)-Objekt wird an jeden [Route-Handler](../basics/routing.md) übergeben.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Es ist das Hauptfenster zum Rest der Funktionalität von Vapor. Es enthält APIs für den [Request-Body](../basics/content.md), [Query-Parameter](../basics/content.md#binden-der-zeichenfolge), den [Logger](../basics/logging.md), den [HTTP-Client](../basics/client.md), den [Authenticator](../security/authentication.md) und mehr. Der Zugriff auf diese Funktionalität über den Request sorgt dafür, dass die Berechnung auf dem richtigen Event-Loop bleibt, und ermöglicht es, sie für Tests zu mocken. Du kannst dem `Request` sogar über Extensions eigene [Services](../advanced/services.md) hinzufügen.

Die vollständige API-Dokumentation für `Request` findest du [hier](https://api.vapor.codes/vapor/documentation/vapor/request).

## Application

Die Eigenschaft `Request.application` enthält eine Referenz auf die [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). Dieses Objekt enthält die gesamte Konfiguration und Kernfunktionalität der Anwendung. Der Großteil sollte nur in `configure.swift` gesetzt werden, bevor die Anwendung vollständig startet, und viele der tiefer liegenden APIs werden in den meisten Anwendungen nicht benötigt. Eine der nützlichsten Eigenschaften ist `Application.eventLoopGroup`, mit der du über die Methode `any()` einen `EventLoop` für Prozesse abrufen kannst, die einen neuen benötigen. Sie enthält außerdem die [`Environment`](../basics/environment.md).

## Body

Wenn du direkten Zugriff auf den Request-Body als `ByteBuffer` möchtest, kannst du `Request.body.data` verwenden. Dies kann genutzt werden, um Daten aus dem Request-Body in eine Datei zu streamen (auch wenn du dafür stattdessen die Eigenschaft [`fileio`](../advanced/files.md) auf dem Request verwenden solltest) oder an einen anderen HTTP-Client.

## Cookies

Auch wenn die nützlichste Anwendung von Cookies über die eingebauten [Sessions](../advanced/sessions.md#konfiguration) erfolgt, kannst du auch direkt über `Request.cookies` auf Cookies zugreifen.

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

Auf ein `HTTPHeaders`-Objekt kann über `Request.headers` zugegriffen werden. Es enthält alle mit dem Request gesendeten Header. Es kann beispielsweise verwendet werden, um auf den `Content-Type`-Header zuzugreifen.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Weitere Dokumentation zu `HTTPHeaders` findest du [hier](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor fügt `HTTPHeaders` außerdem mehrere Extensions hinzu, um die Arbeit mit den am häufigsten verwendeten Headern zu erleichtern; eine Liste ist [hier](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties) verfügbar.

## IP-Adresse

Auf die `SocketAddress`, die den Client repräsentiert, kann über `Request.remoteAddress` zugegriffen werden, was für Logging oder Rate-Limiting mittels der String-Repräsentation `Request.remoteAddress.ipAddress` nützlich sein kann. Sie stellt möglicherweise nicht genau die IP-Adresse des Clients dar, wenn sich die Anwendung hinter einem Reverse-Proxy befindet.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Weitere Dokumentation zu `SocketAddress` findest du [hier](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
