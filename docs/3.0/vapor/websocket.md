# Using WebSockets

Vapor includes convenience methods for working with the lower level WebSocket [client](../websocket/overview.md#client) and [server](../websocket/overview.md#server). 

## Server

Vapor's WebSocket server includes the ability to route incoming requests just like its HTTP server. 

When Vapor's main HTTP [`Server`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Server.html) boots it will attempt to create a [`WebSocketServer`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/WebSocketServer.html). If one is registered, it will be added as an HTTP upgrade handler to the server. 

So to create a WebSocket server, all you need to do is register one in  [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
// Create a new NIO websocket server
let wss = NIOWebSocketServer.default()

// Add WebSocket upgrade support to GET /echo
wss.get("echo") { ws, req in
    // Add a new on text callback
    ws.onText { ws, text in
        // Simply echo any received text
        ws.send(text)
    }
}

// Register our server
services.register(wss, as: WebSocketServer.self)
```

That's it. Next time you boot your server, you will be able to perform a WebSocket upgrade at `GET /echo`.  You can test this using a simple command line tool called [`wsta`](https://github.com/esphen/wsta) available for macOS and Linux.

```sh
$ wsta ws://localhost:8080/echo
Connected to ws://localhost:8080/echo
hello, world!
hello, world!
```

### Parameters

Like Vapor's HTTP router, you can also use routing parameters with your WebSocket server.

```swift
// Add WebSocket upgrade support to GET /chat/:name
wss.get("chat", String.parameter) { ws, req in
    let name = try req.parameters.next(String.self)
    ws.send("Welcome, \(name)!")
    
    // ...
}
```

Now let's test this new route:

```sh
$ wsta ws://localhost:8080/chat/Vapor
Connected to ws://localhost:8080/chat/Vapor
Welcome, Vapor!
```

## Client

Vapor also supports connecting to WebSocket servers as a client. The easiest way to connect to a WebSocket server is through the [`webSocket(...)`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html#/s:5Vapor6ClientPAAE9webSocketXeXeF) method on [`Client`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html).

For this example, we will assume our application connects to a WebSocket server in [`boot.swift`](../getting-started/structure.md#bootswift)

```swift
// connect to echo.websocket.org
let done = try app.client().webSocket("ws://echo.websocket.org").flatMap { ws -> Future<Void> in
    // setup an on text callback that will print the echo
    ws.onText { ws, text in
        print("rec: \(text)")
        // close the websocket connection after we recv the echo
        ws.close()
    }
    
    // when the websocket first connects, send message
    ws.send("hello, world!")
    
    // return a future that will complete when the websocket closes
    return ws.onClose
}

print(done) // Future<Void>
  
// wait for the websocket to close
try done.wait()
```