# Using WebSockets

Unlike HTTP, WebSockets allow you to communicate between client and server in an open, interactive way. You can send messages (called frames) in either text or binary format. Both the client and the server can send as many messages as they want at a time, without having to wait for responses.

Although WebSocket is its own protocol, it still uses HTTP to get setup. Every WebSocket connection will start with an HTTP request with special headers followed by an HTTP response with status `101 Switching Protocols`. After this initial handshake, the connection is a WebSocket connection.

## WebSocket

The [`WebSocket`](https://api.vapor.codes/websocket/latest/WebSocket/Classes/WebSocket.html) class represents a connected WebSocket client. You can use this to set callbacks for receiving data and to send data.

```swift
let ws: WebSocket = ...
// Send an initial message to this WebSocket
ws.send("Hello!")

// Set a new callback for receiving text formatted data
ws.onText { ws, string in
    // Echo the text back, reversed.
    ws.send(string.reversed())
}
```

!!! tip
    All callbacks will receive a reference to the `WebSocket`. Use these if you need to send data to avoid creating a reference cycle.

The `WebSocket` has an [`onClose`](https://api.vapor.codes/websocket/latest/WebSocket/Classes/WebSocket.html#/s:9WebSocketAAC7onCloseXev) future that will be completed when the connection closes. You can use [`close()`](https://api.vapor.codes/websocket/latest/WebSocket/Classes/WebSocket.html#/s:9WebSocketAAC5closeyyF) to close the connection yourself.

## Server

WebSocket servers connect to one or more WebSocket clients at a time. As mentioned previously, WebSocket connections must start via an HTTP request and response handshake. Because of this, WebSocket servers are built on top of [HTTP servers](../http/server.md) using the HTTP upgrade mechanism.

```swift
// First, create an HTTPProtocolUpgrader
let ws = HTTPServer.webSocketUpgrader(shouldUpgrade: { req in
    // Returning nil in this closure will reject upgrade
    if req.url.path == "/deny" { return nil }
    // Return any additional headers you like, or just empty
    return [:]
}, onUpgrade: { ws, req in
    // This closure will be called with each new WebSocket client
    ws.send("Connected")
    ws.onText { ws, string in
        ws.send(string.reversed())
    }
})

// Next, create your server, adding the WebSocket upgrader
let server = try HTTPServer.start(
    ...
    upgraders: [ws],
    ...
).wait()
// Run the server.
try server.onClose.wait()
```

!!! seealso
    Visit [HTTP → Server](../http/server.md) for more information on setting up an HTTP server.

The WebSocket protocol upgrader consists of two callbacks. 

The first callback `shouldUpgrade` receives the incoming HTTP request that is requesting upgrade. This callback decides whether or not to complete the upgrade based on the contents of the request. If `nil` is returned in this closure, the upgrade will be rejected.

The second callback `onUpgrade` is called each time a new WebSocket client connects. This is where you configure your callbacks and send any initial data.

!!! warning
    The upgrade closures may be called on any event loop. Be careful to avoid race conditions if you must access external variables.
    
## Client

You can also use the WebSocket package to connect _to_ a WebSocket server. Just like the WebSocket server used an HTTP server, the WebSocket client uses HTTP client.

```swift
// Create a new WebSocket connected to echo.websocket.org
let ws = try HTTPClient.webSocket(hostname: "echo.websocket.org", on: ...).wait()

// Set a new callback for receiving text formatted data.
ws.onText { ws, text in
    print("Server echo: \(text)")
}

// Send a message.
ws.send("Hello, world!")

// Wait for the Websocket to close.
try ws.onClose.wait()
```

!!! seealso
    Visit [HTTP → Client](../http/client.md) for more information on setting up an HTTP client.

## API Docs

Check out the [API docs](https://api.vapor.codes/websocket/latest/WebSocket/index.html) for more in-depth information about all of the methods.
