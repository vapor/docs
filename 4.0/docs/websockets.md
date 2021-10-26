# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket) allow for two-way communication between a client and server. Unlike HTTP, which has a request and response pattern, WebSocket peers can send an arbitrary number of messages in either direction. Vapor's WebSocket API allows you to create both clients and servers that handle messages asynchronously.

## Server

WebSocket endpoints can be added to your existing Vapor application using the Routing API. Use the `webSocket` method like you would use `get` or `post`. 

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

WebSocket routes can be grouped and protected by middleware like normal routes. 

In addition to accepting the incoming HTTP request, WebSocket handlers accept the newly established WebSocket connection. See below for more information on using this WebSocket to send and read messages.

## Client

To connect to a remote WebSocket endpoint, use `WebSocket.connect`. 

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

The `connect` method returns a future that completes when the connection is established. Once connected, the supplied closure will be called with the newly connected WebSocket. See below for more information on using this WebSocket to send and read messages.

## Messages

The `WebSocket` class has methods for sending and receiving messages as well as listening for events like closure. WebSockets can transmit data via two protocols: text and binary. Text messages are interpreted as UTF-8 strings while binary data is interpreted as an array of bytes.

### Sending

Messages can be sent using the WebSocket's `send` method.

```swift
ws.send("Hello, world")
```

Passing a `String` to this method results in a text message being sent. Binary messages can be sent by passing a `[UInt8]`. 

```swift
ws.send([1, 2, 3])
```

Message sending is asynchronous. You can supply an `EventLoopPromise` to the send method to be notified when the message has finished sending or failed to send. 

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succeeded or failed to send.
}
```

If using `async`/`await` you can `await` on the result

```swift
// TODO Check this actually works
let result = try await ws.send(...)
```

### Receiving

Incoming messages are handled via the `onText` and `onBinary` callbacks.

```swift
ws.onText { ws, text in
    // String received by this WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] received by this WebSocket.
    print(binary)
}
```

The WebSocket itself is supplied as the first parameter to these callbacks to prevent reference cycles. Use this reference to take action on the WebSocket after receiving data. For example, to send a reply:

```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## Closing

To close a WebSocket, call the `close` method. 

```swift
ws.close()
```

This method returns a future that will be completed when the WebSocket has closed. Like `send`, you may also pass a promise to this method.

```swift
ws.close(promise: nil)
```

Or `await` on it if using `async`/`await`:

```swift
try await ws.close()
```

To be notified when the peer closes the connection, use `onClose`. This future will be completed when either the client or server closes the WebSocket.

```swift
ws.onClose.whenComplete { result in
    // Succeeded or failed to close.
}
```

The `closeCode` property is set when the WebSocket closes. This can be used to determine why the peer closed the connection.

## Ping / Pong

Ping and pong messages are sent automatically by the client and server to keep WebSocket connections alive. Your application can listen for these events using the `onPing` and `onPong` callbacks.

```swift
ws.onPing { ws in 
    // Ping was received.
}

ws.onPong { ws in
    // Pong was received.
}
```
