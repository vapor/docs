# Solicitud (Request)

El objeto [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) (solicitud) se pasa a cada [controlador de ruta](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Es la ventana principal al resto de la funcionalidad de Vapor. Contiene APIs para el [cuerpo de la solicitud](../basics/content.md), [parámetros de consulta](../basics/content.md#query), [logger](../basics/logging.md), [cliente HTTP](../basics/client.md), [Autenticador](../security/authentication.md) y más. Accediendo a esta funcionalidad a través de la solicitud, se mantiene el cálculo en el bucle de eventos correcto y permite simularla para realizar pruebas. Incluso puedes añadir tus propios [servicios](../advanced/services.md) a la `Request` con extensiones.

La documentación completa de la API para `Request` se puede encontrar [aquí](https://api.vapor.codes/vapor/documentation/vapor/request).

## Aplicación

La propiedad `Request.application` contiene una referencia a la [`Aplicación`](https://api.vapor.codes/vapor/documentation/vapor/application). Este objeto contiene toda la configuración y la funcionalidad central de la aplicación. La mayor parte solo se debe configurar en `configure.swift`, antes de que la aplicación se inicie por completo, y muchas de las APIs de bajo nivel no serán necesarias en la mayoría de las aplicaciones. Una de las propiedades más útiles es `Application.eventLoopGroup`, que se puede utilizar para obtener un `EventLoop` para los procesos que necesitan uno nuevo a través del método `any()`. También contiene el [`Entorno`](../basics/environment.md).

## Body

Si quieres acceder directamente al cuerpo de la solicitud como un `ByteBuffer`, puedes utilizar `Request.body.data`. Esto puede utilizarse para transmitir datos desde el cuerpo de la solicitud a un archivo (aunque para esto deberías utilizar la propiedad [`fileio`](../advanced/files.md) en la solicitud) o a otro cliente HTTP.

## Cookies

Aunque la aplicación más útil de las cookies es a través de las [sesiones](../advanced/sessions.md#configuration) integradas, también puedes acceder a las cookies directamente a través de `Request.cookies`.

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

## Cabeceras

Se puede acceder a un objeto `HTTPHeaders` en `Request.headers`. Contiene todas las cabeceras enviadas con la solicitud. Se puede utilizar para acceder a la cabecera `Content-Type`, por ejemplo.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Consulta más documentación sobre `HTTPHeaders` [aquí](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor también añade varias extensiones a `HTTPHeaders` para facilitar el trabajo con las cabeceras más utilizadas; la lista está disponible [aquí](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)

## Dirección IP

Puedes acceder a la `SocketAddress` que representa al cliente a través de `Request.remoteAddress`, que puede ser útil para el registro o la limitación de velocidad utilizando la representación de la cadena `Request.remoteAddress.ipAddress`. Puede que no represente con exactitud la dirección IP del cliente si la aplicación está detrás de un proxy inverso.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Consulta más documentación sobre `SocketAddress` [aquí](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
