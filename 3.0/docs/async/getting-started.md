# Getting Started with Async

Vapor is powered by Apple's [SwiftNIO](https://github.com/apple/swift-nio), a powerful non-blocking networking framework. If you are using the fully-powered Vapor framework to create a website, then you will likely not need to use this directly. However, if you are using a lower-level library (like a Database framework) then you will need to understand a little about how it works.

## Workers

Vapor's async abstraction is built on a few pieces, including the async [`Worker`](https://github.com/vapor-community/async/blob/1.0.0-rc.1.1/Sources/Async/EventLoop/Worker.swift). This protocol has an `eventLoop`, which fits nicely with SwiftNIO's constructs.

### Example

You need to create a SwiftNIO [`EventGroup`](https://github.com/apple/swift-nio/blob/master/README.md#eventloops-and-eventloopgroups) that can power the connection:

```
let database = MySQLDatabase(config: config)
let worker = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
let futureConnection = database.makeConnection(on: worker)
```
