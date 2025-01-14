# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket) permiten la comunicación bidireccional entre un cliente y un servidor. A diferencia de HTTP, que tiene un patrón de solicitud y respuesta, los pares de WebSocket pueden enviar una cantidad arbitraria de mensajes en cualquier dirección. La API WebSocket de Vapor te permite crear tanto clientes como servidores que manejan mensajes de forma asincrónica.

## Servidor

Los endpoints de WebSocket se pueden agregar a tu aplicación Vapor existente mediante la API de enrutamiento. Usa el método `webSocket` como usarías `get` o `post`.

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

Las rutas de WebSocket se pueden agrupar y proteger mediante middleware como las rutas normales.

Además de aceptar la solicitud HTTP entrante, los controladores de WebSocket aceptan la conexión WebSocket recién establecida. Consulta a continuación para obtener más información sobre el uso de este WebSocket para enviar y leer mensajes.

## Cliente

Para conectarse a un endpoint remoto de WebSocket, use `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // WebSocket conectado.
    print(ws)
}
```

El método `connect` devuelve un futuro que se completa cuando se establece la conexión. Una vez conectado, se llamará al closure proporcionado con el WebSocket recién conectado. Mira más información a continuación sobre el uso de este WebSocket para enviar y leer mensajes.

## Mensajes

La clase `WebSocket` tiene métodos para enviar y recibir mensajes, así como para escuchar eventos como el closure. Los WebSockets pueden transmitir datos a través de dos protocolos: texto y binario. Los mensajes de texto se interpretan como cadenas UTF-8, mientras que los datos binarios se interpretan como una matriz de bytes.

### Envío

Los mensajes se pueden enviar utilizando el método `send` de WebSocket.

```swift
ws.send("Hello, world")
```

Pasar una `String` a este método da como resultado el envío de un mensaje de texto. Los mensajes binarios se pueden enviar pasando un `[UInt8]`.

```swift
ws.send([1, 2, 3])
```

El envío de mensajes es asincrónico. Puede proporcionar un `EventLoopPromise` al método de envío para recibir una notificación cuando el mensaje haya terminado de enviarse o falle en el envío.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Envío exitoso o fallido.
}
```

Si usas `async`/`await`, puedes usar `await` para esperar a que se complete la operación asincrónica

```swift
try await ws.send(...)
```

### Recepción

Los mensajes entrantes se manejan a través de los callbacks `onText` y `onBinary`.

```swift
ws.onText { ws, text in
    // Cadena recibida por este WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] recibido por este WebSocket.
    print(binary)
}
```

El propio WebSocket se proporciona como el primer parámetro de estos callbacks para evitar ciclos de referencia. Usa esta referencia para realizar una acción en el WebSocket después de recibir datos. Por ejemplo, para enviar una respuesta:

```swift
// Se hace eco de los mensajes recibidos.
ws.onText { ws, text in
    ws.send(text)
}
```

## Cierre

Para cerrar un WebSocket, llama al método `close`.

```swift
ws.close()
```

Este método devuelve un futuro que se completará cuando el WebSocket se haya cerrado. Al igual que `send`, también puede pasar una promesa a este método.

```swift
ws.close(promise: nil)
```

O `await` si usas `async`/`await`:

```swift
try await ws.close()
```

Para recibir una notificación cuando el par cierra la conexión, utiliza `onClose`. Este futuro se completará cuando el cliente o el servidor cierren el WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Cierre exitoso o fallido.
}
```

La propiedad `closeCode` se establece cuando el WebSocket se cierra. Esto se puede utilizar para determinar por qué el par cerró la conexión.

## Ping / Pong

El cliente y el servidor envían automáticamente mensajes de ping y pong para mantener activas las conexiones WebSocket. Su aplicación puede escuchar estos eventos mediante los callbacks `onPing` y `onPong`.

```swift
ws.onPing { ws in 
    // Se recibió ping.
}

ws.onPong { ws in
    // Se recibió pong.
}
```
