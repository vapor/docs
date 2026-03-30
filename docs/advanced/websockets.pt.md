# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket) permitem comunicação bidirecional entre um cliente e servidor. Diferente do HTTP, que tem um padrão de requisição e resposta, peers WebSocket podem enviar um número arbitrário de mensagens em qualquer direção. A API de WebSocket do Vapor permite que você crie tanto clientes quanto servidores que lidam com mensagens de forma assíncrona.

## Servidor

Endpoints WebSocket podem ser adicionados à sua aplicação Vapor existente usando a API de Roteamento. Use o método `webSocket` como você usaria `get` ou `post`.

```swift
app.webSocket("echo") { req, ws in
    // WebSocket conectado.
    print(ws)
}
```

Rotas WebSocket podem ser agrupadas e protegidas por middleware como rotas normais.

Além de aceitar a requisição HTTP de entrada, handlers WebSocket aceitam a conexão WebSocket recém-estabelecida. Veja abaixo para mais informações sobre como usar este WebSocket para enviar e ler mensagens.

## Cliente

Para conectar a um endpoint WebSocket remoto, use `WebSocket.connect`.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // WebSocket conectado.
    print(ws)
}
```

O método `connect` retorna um future que se completa quando a conexão é estabelecida. Uma vez conectado, a closure fornecida será chamada com o WebSocket recém-conectado. Veja abaixo para mais informações sobre como usar este WebSocket para enviar e ler mensagens.

## Mensagens

A classe `WebSocket` possui métodos para enviar e receber mensagens, bem como ouvir eventos como fechamento. WebSockets podem transmitir dados via dois protocolos: texto e binário. Mensagens de texto são interpretadas como strings UTF-8, enquanto dados binários são interpretados como um array de bytes.

### Envio

Mensagens podem ser enviadas usando o método `send` do WebSocket.

```swift
ws.send("Hello, world")
```

Passar uma `String` para este método resulta em uma mensagem de texto sendo enviada. Mensagens binárias podem ser enviadas passando um `[UInt8]`.

```swift
ws.send([1, 2, 3])
```

O envio de mensagens é assíncrono. Você pode fornecer um `EventLoopPromise` ao método send para ser notificado quando a mensagem terminou de ser enviada ou falhou.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Enviou com sucesso ou falhou.
}
```

Se estiver usando `async`/`await`, você pode usar `await` para aguardar a conclusão da operação assíncrona

```swift
try await ws.send(...)
```

### Recebimento

Mensagens de entrada são tratadas através dos callbacks `onText` e `onBinary`.

```swift
ws.onText { ws, text in
    // String recebida por este WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] recebido por este WebSocket.
    print(binary)
}
```

O próprio WebSocket é fornecido como primeiro parâmetro desses callbacks para evitar ciclos de referência. Use esta referência para tomar ação no WebSocket após receber dados. Por exemplo, para enviar uma resposta:

```swift
// Ecoa mensagens recebidas.
ws.onText { ws, text in
    ws.send(text)
}
```

## Fechamento

Para fechar um WebSocket, chame o método `close`.

```swift
ws.close()
```

Este método retorna um future que será completado quando o WebSocket for fechado. Como `send`, você também pode passar uma promise para este método.

```swift
ws.close(promise: nil)
```

Ou usar `await` se estiver usando `async`/`await`:

```swift
try await ws.close()
```

Para ser notificado quando o peer fechar a conexão, use `onClose`. Este future será completado quando o cliente ou o servidor fechar o WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Fechou com sucesso ou falhou.
}
```

A propriedade `closeCode` é definida quando o WebSocket fecha. Pode ser usada para determinar por que o peer fechou a conexão.

## Ping / Pong

Mensagens de ping e pong são enviadas automaticamente pelo cliente e servidor para manter conexões WebSocket ativas. Sua aplicação pode ouvir esses eventos usando os callbacks `onPing` e `onPong`.

```swift
ws.onPing { ws in
    // Ping foi recebido.
}

ws.onPong { ws in
    // Pong foi recebido.
}
```
