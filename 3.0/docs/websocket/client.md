# WebSocket Client

WebSocket clients work the same on the client side as the [server side](server.md).

## Connecting a WebSocket client

WebSockets require an [URI](../http/uri.md) to connect to and a DispatchQueue to run on.

```swift
let queue: DispatchQueue = ...

let futureWebSocket: Future<WebSocket> = try WebSocket.connect(to: "ws://localhost/path", queue: queue)
```

## Using websockets

WebSockets are interacted with using [binary streams](binary-stream.md) or [text streams](text-stream.md).

All other information about websockets [is defined here.](websocket.md)
