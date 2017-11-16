# Introduction into Streams

Streams is a mechanism that you can implement on objects that process any information efficiently and asynchronously without bloat.

There are three primary stream protocols:

- InputStream
- OutputStream
- Stream

Conforming to Stream means conformance to both InputStream and OutputStream. So `Stream` is both processing output and providing output.

InputStream is a protocol that, when implemented, accepts streaming input. An example can be a TCP socket that, on input, writes data to the socket.

OutputStream is a protocol that, when implement, can emit output.

### Concept

In Vapor 3 (related libraries), almost everything is a stream. TCP Server is a stream of clients. Each client is a stream of received binary data. For HTTP, each client has an HTTP Request Parser, and Response Serializer. A parser accepts the binary stream and outputs a request stream. And a responder accepts a response and outputs a binary stream (that you can send back to the client's TCP socket as input for the binary stream).

## Draining streams

Now that we've seen how to chain streams, let's talk about draining. In this example the [TCP Server](../sockets/tcp-server.md) accepts a client stream which can be drained with a closure. This allows additional processing to take place.

In this example we print the string representation of the TCP connnection's incoming data.

```swift
tcpSocket.drain { buffer in
  print(String(bytes: buffer, encoding: .utf8))
}
```

Another use case for draining is when the stream does not need to be continued any further. After a [Response](../http/response.md) has been sent to the Client, nothing else needs to happen.

## Catching stream errors

When a (fatal) error occurs, often something need to happen. Many chained streams will do a sensible default. Sockets will close, for example. You can hook into this process by `.catch`-ing a stream's errors.

```swift
stream.catch { error in
  // Do something with the error
  print(error)
}
```

## Implementing an example stream

This example is a stream that deserializes `ByteBuffer` to `String` streaming/asynchronously.

```swift
struct InvalidUTF8 : Error {}

// Deserializes `ByteBuffer` (`Input`) to `String` (`Output`) using the provided encoding
class StringDeserializationStream: Async.Stream {
    typealias Input = ByteBuffer
    typealias Output = String

    // Used only by this specific stream to specify an encoding
    let encoding: String.Encoding

    // MARK: Stream requirements

    // An error stream that can be listened to for errors in this stream
    var errorStream: BaseStream.ErrorHandler?

    // A handler that can be set to handle output
    var outputStream: OutputHandler?

    // Creates a new `StringDeserializationStream`
    init(encoding: String.Encoding = .utf8) {
        // Sets the String encoding
        self.encoding = encoding
    }

    // Receives `Input`/`ByteBuffer` from another stream or manual call
    //
    // Attempts to process it to a String using the specified encoding
    func inputStream(_ input: Input) {
        // Converts the `Input`/`ByteBuffer` to a String
        guard let string = String(bytes: input, encoding: self.encoding) {
            // Stream an error if string initialization failed
            self.errorStream?(InvalidUTF8())
            return
        }

        // On success, output the created string
        self.outputStream?(string)
    }
}
```

## Transforming streams without an intermediary stream

The above stream `StringDeserializationStream` is a very simple example of implementing a stream.

Streams support two kinds of transforms. `flatMap` and `map`. Map transforms the output of the stream into a new stream with different output. And `flatMap` does the same, but allows returning `nil` and does not output it.

```swift
// `flatMap`s the data into a `String?`. If the string results in `nil`, the resulting `stringStream` does not get called.
// `stringStream` is a stream outputting `String`
let stringStream = tcpStream.flatMap { bytes in
  return String(bytes: bytes, encoding: .utf8)
}

// `map`s the data into a `String?`. If the string results in `nil`, the resulting `optionalStringStream` emits `nil`, too.
// `optionalStringStream` is a stream outputting `String?`
let optionalStringStream = tcpStream.map { bytes in
  return String(bytes: bytes, encoding: .utf8)
}
```

As you see, you an provide a closure to do the mapping for you. If you want to reuse this code instead, you could make it a function for simplicity. This function can then be used instead of the closure.

```swift
// Creates a `String` from `ByteBuffer`. This can return `nil` if the `ByteBuffer` doesn't contain valid UTF-8
func utf8String(from bytes: ByteBuffer) -> String? {
  return String(bytes: bytes, encoding: .utf8)
}

// `flatMap`s the data into a `String?`. If the string results in `nil`, the resulting `stringStream` does not get called.
// `stringStream` is a stream outputting `String`
let stringStream = tcpStream.flatMap(utf8String)

// `map`s the data into a `String?`. If the string results in `nil`, the resulting `optionalStringStream` emits `nil`, too.
// `optionalStringStream` is a stream outputting `String?`
let optionalStringStream = tcpStream.map(utf8String)
```
