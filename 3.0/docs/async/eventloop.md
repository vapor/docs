# EventLoop

EventLoops are loops that listen for events in file descriptors that indicate being able to read or write data.

In addition to the above, they're also able to run single tasks inbetween listening for events.

There are three main forms of eventloops.

`DispatchEventLoop` is based on Dispatch, `KQueueEventLoop` is a macOS-only eventloop that is more performant than Dispatch.

The third one (currently work in progress) is the `EPollEventLoop`, a Linux only eventloop that is also more performant than Dispatch.

### Workers

To carry around context, the `Worker` protocol exists to indicate the current eventloop context.

### Future changes during beta

It is likely that we'll start inferring the current EventLoop using the Thread Local Storage, removing the need for Workers and passing EventLoop as an argument.

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
