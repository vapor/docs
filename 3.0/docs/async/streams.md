# Streams

Streams are a mechanism that process any information efficiently, [reactively](reactive.md) and asynchronously without bloat.

Streams are designed to limit memory usage and copies. They are used in all domains of Vapor 3, be it sockets, be it (larger) database operations.

## Draining streams

In this example we print the string representation of the TCP connnection's incoming data.

Since this socket is reactive we need to first request data before we can expect a result.
After requesting data we need to set up the output

```swift
import Async
import Foundation

...

tcpSocket.drain { upstream in
    upstream.request()
}.output { buffer in
    print(String(bytes: buffer, encoding: .utf8))
    tcpSocket.request()
}.catch { error in
    print("Error occurred \(error)")
}.finally {
    print("TCP socket closed")
}
```

In the above implementation we explicitly request more information from the socket after receiving output.

## Emitting output

Emitter streams are useful if you don't want to create your own reactive stream implementation.

They allow emitting output easily which can then be used like any other stream.

```swift
let emitter = EmitterStream<Int>()

emitter.drain { upstream in
  upstream.request()
}.output { number in
  print(number)
  emitter.request()
}

emitter.emit(3)
emitter.emit(4)
emitter.emit(3)
emitter.emit(5)
```

## Mapping Streams

To transform a string to another type you can map it similarly to futures.
The following assumes `stream` contains a stream of `Int` as defined in the above emitter.

```swift
let stringStream = emitter.map(to: String.self) { number in
  return number.description
}
```

## Implementing custom streams

Coming soon
