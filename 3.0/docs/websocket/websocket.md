# WebSocket

WebSockets are a type of connection that can be instantiated by upgrading an existing HTTP/1.1 connection. They're used to dispatch notifications and communicate real-time binary and textual Data.

Vapor 3 supports both WebSocket Clients and server-side sockets.

### Server side Sockets

Vapor 3 adds a helper to routing that helps accepting clients.

```swift
import WebSocket

routing.websocket("api/v1/websocket") { req, websocket in
  // set up the websocket
}
```
### Client side sockets

Connecting to a remote WebSocket is relatively painless. You can provide a URL and Vapor 3 will attempt to set up a connection.

For creating an SSL connection, however, a [container](../services/getting-started.md) must be provided.

!!! warning
	Vapor does not retain the WebSocket. You need to keep the WebSocket active by means of strong references and pings.

```swift
let futureWebSocket = try WebSocket.connect(to: "ws://localhost/path", using: container) // Future<WebSocket>
```

## Using websockets

### Sending strings

Sending a `String` using a WebSocket sends it to the remote.

```swift
webSocket.send(string: string)
```

### Receiving strings

String data can be read using the following function. Only one closure can read at a time.

```swift
webSocket.onString { string in
  // use the `String`
}
```

### Sending binary data

Sending a `Data` or `ByteBuffer` using a WebSocket sends it to the remote.

```swift
webSocket.send(bytes: byteBuffer)
webSocket.send(data: data)
```

### Receiving binary data

Binary data can be read as a `ByteBuffer` using the following function. Only one closure can read at a time.

```swift
webSocket.onByteBuffer { byteBuffer in
  // use the `ByteBuffer`
}
```

Binary data can also, instead, be used as Foundation's `Data`. This is less efficient than `ByteBuffer` but is often easier to use.

```swift
webSocket.onData { data in
  // use the `Data`
}
```

Setting a listener will override all previous listeners. You need to split into multiple listeners manually.

### On close

When requesting data using the `onString`, `onByteBuffer` and/or `onData` functions, you'll receive a handle to that stream.
This can be used for catching errors and detecting the websocket being closed.

```swift
webSocket.onString { websocket, string in
    print(string)
}.catch { error in
	print("Error occurred: \(error)")
}.finally {
	print("closed")
}
```

### Errors

Any error in a WebSocket will close the connection. This notification will be received on the binary _and_ text streams.
