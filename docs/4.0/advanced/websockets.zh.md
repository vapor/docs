# WebSockets

[WebSockets](https://zh.wikipedia.org/wiki/WebSocket) 允许客户端和服务器之间进行双向通信。与 HTTP 的请求和响应模式不同，WebSocket 可以在两端之间发送任意数量的消息。Vapor 的 WebSocket API 允许你创建异步处理消息的客户端和服务器。

## 服务器

你可以使用 [Routing API](../basics/routing.md) 将 WebSocket 端点添加到现有的 Vapor 应用程序中。使用 `webSocket` 的方法就像使用 `get` 或 `post` 一样。

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

WebSocket 路由可以像普通路由一样由中间件进行分组和保护。

除了接受传入的 HTTP 请求之外，WebSocket 处理程序还可以接受新建立的 WebSocket 连接。有关使用此 WebSocket 发送和阅读消息的更多信息，请参考下文。

## 客户端

要连接到远程 WebSocket 端口，请使用 `WebSocket.connect` 。

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

`connect` 方法返回建立连接后完成的 future。 连接后将使用新连接的 WebSocket 调用提供的闭包。有关使用 WebSocket 发送和阅读消息的更多信息，请参见下文。

## 消息

`WebSocket` 类具有发送和接收消息以及侦听诸如关闭之类的方法。WebSocket 可以通过两种协议传输数据：文本以及二进制数据。文本消息为 UTF-8 字符串，而二进制数据为字节数组。

### 发送

可以使用 WebSocket 的 `send` 方法来发送消息。

```swift
ws.send("Hello, world")
```

将 `String` 传递给此方法即可发送文本消息。二进制消息可以通过如下传递 `[UInt8]` 数据来发送：

```swift
ws.send([1, 2, 3])
```

发送消息是异步处理，你可以向 send 方法提供一个 `EventLoopPromise`，以便在消息发送完成或发送失败时得到通知。

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // 发送成功或失败。
}
```

如果使用 `async`/`await`，你可以使用 `await` 来等待异步操作完成。

```swift
try await ws.send(...)
```

### 接收

接收的消息通过 `onText` 和 `onBinary` 回调进行处理。

```swift
ws.onText { ws, text in
    // 这个方法接收的是字符串。
    print(text)
}

ws.onBinary { ws, binary in
    // 这个方法接收二进制数组。
    print(binary)
}
```

WebSocket 对象本身作为这些回调的第一个参数提供，以防止循环引用。接收数据后，使用此引用对 WebSocket 采取对应操作。例如，发送回复信息：

```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## 关闭

如果要关闭 WebSocket，请调用 `close` 方法。

```swift
ws.close()
```

该方法返回的 future 将在 WebSocket 关闭时完成。你也可以像 `send` 方法一样，向该方法传递一个 promise。

```swift
ws.close(promise: nil)
```

要在对方关闭连接时收到通知，请使用 `onClose`。这样当客户端或服务器关闭 WebSocket 时，将会触发此 future 方法。

```swift
ws.onClose.whenComplete { result in
    // 关闭成功或失败。
}
```

当 WebSocket 关闭时会返回 `closeCode` 属性，可用于确定对方关闭连接的原因。

## Ping / Pong

客户端和服务器会自动发送 ping 和 pong 心跳消息，来保持 WebSocket 的连接。你的程序可以使用 `onPing` 和 `onPong` 回调监听这些事件。

```swift
ws.onPing { ws in 
    // 接收到了 Ping 消息。
}

ws.onPong { ws in
    // 接收到了 Pong 消息。
}
```


