# Stream Basics

Streams are a set of events that occur asynchronously in time. Some events may dispatch immediately, and others may have a delay in nanoseconds, milliseconds, minutes or any other duration. Streams can be linked together to create simple, performant and maintainable software.

## Chaining streams

If an `OutputStream`'s Output is the same as an `InputStream`'s input, you can "chain" these streams together to create really performant and readable solutions.

This doesn't work for all situation, but let's look at an example that *does* accept [base64](../crypto/base64.md).

```swift
client.stream(to: base64encoder).stream(to: client)
```

The result is an "echo" server that base64-encodes incoming data, and replies it back in base64-encoded format.

Another good example is how Vapor processes requests internally.

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
