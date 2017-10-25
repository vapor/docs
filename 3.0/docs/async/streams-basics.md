# Stream Basics

## Chaining streams

Streams can be chained. One Stream's output can be the other's input.

To make this accessible we added stream chaining. One good example is how Vapor processes requests internally.

```swift
let server = try TCPServer(port: 8080, worker: Worker(queue: myDispatchQueue))

// Servers are a stream of accepted web client connections
// Clients are an input and output stream of bytes
server.drain { client in
    let parser = RequestParser()
    let router = try yourApplication.make(Router.self)
    let serialiser = ResponseSerializer()

    // Parses client-sent bytes into the RequestParser
    let requestStream = client.stream(to: parser)

    // Parses requests to the Vapor router, creating a response
    let responseStream = requestStream.stream(to: router)

    // Serializes the responses, creating a byte stream
    let serializedResponseStream = responseStream.stream(to: serializer)

    // Drains the serialized responses back into the client socket
    serializedResponseStream.drain(into: client)
}
```

In the above example, the output of one stream is inputted into another. This ends up taking care of the entire HTTP [Request](../http/request.md)/[Response](../http/response.md) process.

`Socket -> Request-Data -> Request -> Processing -> Response -> Response-Data -> Socket`

## Draining streams

In the above example an example of chaining streams was shown. Part of this example demonstrates draining streams. In this example the [TCP Server](../sockets/tcp-server.md) accepts clients. This client stream can be drained. This stream can be drained with a closure in which more processing can take place.

In this example we used the closure to set up a parsing/serialization context per accepted connection.

Another use case for draining is when the stream does not need to be continued any further. After a [Response](../http/response.md) has been sent to the Client, nothing else needs to happen.

## Catching stream errors

When a (fatal) error occurs, often something need to happen. Many chained streams will do a sensible default. Sockets will close, for example. You can hook into this process by `.catch`-ing a stream's errors.

```swift
stream.catch { error in
  // Do something with the error
  print(error)
}
```
