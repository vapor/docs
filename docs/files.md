# Files

Vapor offers a simple API for reading and writing files asynchronously within route handlers. This API is built on top of NIO's [`NonBlockingFileIO`](https://apple.github.io/swift-nio/docs/current/NIOPosix/Structs/NonBlockingFileIO.html) type.

## Read

The main method for reading a file delivers chunks to a callback handler as they are read off the disk. The file to read is specified by its path. Relative paths will look in the process's current working directory.

```swift
// Asynchronously reads a file from disk.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Or

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Read is complete
```

If using `EventLoopFuture`s, the returned future will signal when the read has completed or an error has occurred. If using `async`/`await` then once the `await` has return the read has completed. If an error has occurred it will throw an error.

### Stream

The `streamFile` method converts a streaming file to a `Response`. This method will set appropriate headers such as `ETag` and `Content-Type` automatically.

```swift
// Asynchronously streams file as HTTP response.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Or

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

The result can be returned directly by your route handler. 

### Collect 

The `collectFile` method reads the specified file into a buffer.

```swift
// Reads the file into a buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// or

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning
    This method requires the entire file to be in memory at once. Use chunked or streaming read to limit memory usage.

## Write

The `writeFile` method supports writing a buffer to a file.

```swift
// Writes buffer to file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

The returned future will signal when the write has completed or an error has occurred.

## Middleware

For more information on serving files from your project's _Public_ folder automatically, see [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Advanced

For cases that Vapor's API doesn't support, you can use NIO's `NonBlockingFileIO` type directly. 

```swift
// Main thread.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// In a route handler.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

For more information, visit SwiftNIO's [API reference](https://apple.github.io/swift-nio/docs/current/NIOPosix/Structs/NonBlockingFileIO.html).
