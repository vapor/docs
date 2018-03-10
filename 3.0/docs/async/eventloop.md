# EventLoop

Event loops are at the heart of Vapor's non-blocking concurrency model. There is usually one event loop per logical core. The event loop's main purpose is to detect when a file or (TCP) socket is ready to be read from or written to. By detecting socket events before actually attempting to read or write data, Vapor can avoid making function calls that may block. Avoiding blocking calls is critical for performance as it allows Vapor to aggressively re-use threads, making your app very fast and efficient.

In addition to the above, they're also able to run single tasks inbetween listening for events.

`EpollEventLoop` is a Linux-only eventloop and `KqueueEventLoop` is a macOS-only eventloop. Both are more performant than Dispatch for server-side operations.

### Workers

The `Worker` protocol exists to indicate the current eventloop context.

```swift
worker.eventLoop // EventLoop
```

When looking for a worker, the most common ones you'll come across are the `Request` and `Response`.

## Sources

To add/remove listeners from EventLoops you can ask for a readable or writable source or `EventSource`. EventSources are a handle which can be resumed, suspended and cancelled.
When requesting said handle on an EventLoop you must provide a closure which calls back with the notification.

This notification indicates that data is available for work in the provided descriptor. This includes the descriptor being closed.

```swift
let sourceHandle = eventLoop.onReadable(descriptor: socket.descriptor) { cancelled in
  if cancelled {
    print("descriptor closed")
  } else {
    print("Data is readable")
  }
}
```

Write sources are the opposite of a Source in that they notify the ability to write data. They should be suspended after the first write so that they do not call back every loop.

Whilst Sources indicate the availability of data, Drains

## Sockets

As part of the EventLoops in Vapor 3, we also centralized the asynchronous part of Sockets, simplifying the APIs for I/O and improving it's asynchronous usability. It is recommended for (raw) TCP, (raw) UDP and SSL implementations to conform to the `Socket` protocol.

### SocketSink and SocketSource

`SocketSink` is a helper that assists with writing data to sockets reactively.
`SocketSource` is a helper that functions as the Sink's counterpart with reading data from sockets reactively.

```swift
let sink = socket.sink(on: eventLoop)
```
