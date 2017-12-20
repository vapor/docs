# TCP Clients

Sockets are a connection to another endpoint. They're usually connected to the internet, but may also run over a VPN or the local loopback (to your own computer). Sockets in Vapor currently only support asynchronous TCP sockets.

## Creating and connecting a socket

The first step is to create a new socket.

```swift
let socket = try Socket()
```

This socket is not connected to anything yet. To connect it you need to call the `connect` function with a hostname and port.

```swift
try socket.connect(hostname: "example.com", port: 80)
```

After connecting, your socket may not be ready yet. Since this socket is asynchronous, the `connect` phase may not be over yet.

You'll have to add a `writable` notification to a queue.

```swift
let connectedNotification = try socket.writable() // Future<Void>
```

At this point, a successful client socket has been created. You can either [interact with sockets manually](tcp-socket.md) or continue using the `TCPClient` helpers. In the second case, continue reading this article and wrap the socket.

```swift
let client = TCPClient(socket: socket, eventLoop: eventLoop)
```

## Communicating

Now that your socket is connected you can start communicating. First, you'll need to start by setting up the handlers for incoming data.

Since `TCPClient` is a stream, you can use [the introduction](../async/streams.md) of streams for reading the socket's output (incoming data).

Sending data is done through the `inputStream` function.

```swift
client.inputStream(data) // Sends `Data`
```

This accepts `ByteBuffer`, `Data` and `DispatchData`. Chaining streams into this `TCPClient`, however, requires a `ByteBuffer`.

Once your client is all set up, `start()` reading.

```swift
client.start()
```
