# Using HTTPServer

HTTP servers respond to incoming [`HTTPRequests`](https://api.vapor.codes/http/latest/HTTP/Structs/HTTPRequest.html) with [`HTTPResponses`](https://api.vapor.codes/http/latest/HTTP/Structs/HTTPResponse.html). The [`HTTPServer`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPServer.html) type is what powers Vapor's higher-level server. This short guide will show you how to set up your own HTTP server manually.

!!! tip
	If you are using Vapor, you probably don't need to use HTTP's APIs directly. Refer to [Vapor &rarr; Getting Started](../vapor/getting-started.md) for the more convenient APIs.

## Responder

Creating an HTTP server is easy, and only takes a few lines of code. The first step is to create an [`HTTPServerResponder`](https://api.vapor.codes/http/latest/HTTP/Protocols/HTTPServerResponder.html). This will be directly responsible for generating responses to incoming requests.

Let's create a simple responder that will echo the request's content.

```swift
/// Echoes the request as a response.
struct EchoResponder: HTTPServerResponder {
	/// See `HTTPServerResponder`.
    func respond(to req: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
    	// Create an HTTPResponse with the same body as the HTTPRequest
    	let res = HTTPResponse(body: req.body)
    	// We don't need to do any async work here, we can just
    	// se the Worker's event-loop to create a succeeded future.
        return worker.eventLoop.newSucceededFuture(result: res)
    }
}
```

## Start

Now that we have a responder, we can create our [`HTTPServer`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPServer.html). We just need to choose a hostname and port for the server to bind to. In this example, we will bind to `http://localhost:8123`.

```swift
// Create an EventLoopGroup with an appropriate number
// of threads for the system we are running on.
let group = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
// Make sure to shutdown the group when the application exits.
defer { try! group.syncShutdownGracefully() }

// Start an HTTPServer using our EchoResponder
// We are fine to use `wait()` here since we are on the main thread.
let server = try HTTPServer.start(
	hostname: "localhost", 
	port: 8123, 
	responder: EchoResponder(), 
	on: group
).wait()

// Wait for the server to close (indefinitely).
try server.onClose.wait()
```

The static [`start(...)`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPServer.html#/s:4HTTP10HTTPServerC5startXeXeFZ) method creates and returns a new [`HTTPServer`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPServer.html) asynchronously. The future will be completed when the server has finished booting succesfully, or it will contain an error if something went wrong.

Once the start future is complete, our server is running. By waiting for the server's `onClose` future to complete, we can keep our application alive until the server closes. Normally the server will not close itself--it will just run indefinitely. However if `server.close()` is ever called, the application can exit gracefully.

## API Docs

That's it! Congratulations on making your first HTTP server and responder. Check out the [API docs](https://api.vapor.codes/http/latest/HTTP/index.html) for more in-depth information about all of the available parameters and methods.
