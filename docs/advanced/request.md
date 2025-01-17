# Request

The [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) object is passed into every [route handler](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

It is the main window into the rest of Vapor's functionality. It contains APIs for the [request body](../basics/content.md), [query parameters](../basics/content.md#query), [logger](../basics/logging.md), [HTTP client](../basics/client.md), [Authenticator](../security/authentication.md), and more. Accessing this functionality through the request keeps computation on the correct event loop and allows it to be mocked for testing. You can even add your own [services](../advanced/services.md) to the `Request` with extensions.

The full API documentation for `Request` can be found [here](https://api.vapor.codes/vapor/documentation/vapor/request).

## Application

The `Request.application` property holds a reference to the [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). This object contains all of the configuration and core functionality for the application. Most of it should only be set in `configure.swift`, before the application fully starts, and many of the lower level APIs won't be needed in most applications. One of the most useful properties is `Application.eventLoopGroup`, which can be used to get an `EventLoop` for processes that need a new one via the `any()` method. It also contains the [`Environment`](../basics/environment.md).

## Body

If you want direct access to the request body as a `ByteBuffer`, you can use `Request.body.data`. This can be used for streaming data from the request body to a file (though you should use the [`fileio`](../advanced/files.md) property on the request for this instead) or to another HTTP client.

## Cookies

While the most useful application of cookies is via built-in [sessions](../advanced/sessions.md#configuration), you can also access cookies directly via `Request.cookies`.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

An `HTTPHeaders` object can be accessed at `Request.headers`. This contains all of the headers sent with the request. It can be used to access the `Content-Type` header, for example.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

See further documentation for `HTTPHeaders` [here](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor also adds several extensions to `HTTPHeaders` to make working with the most commonly-used headers easier; a list is available [here](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)

## IP Address

The `SocketAddress` representing the client can be accessed via `Request.remoteAddress`, which may be useful for logging or rate limiting using the string representation `Request.remoteAddress.ipAddress`. It may not accurately represent the client's IP address if the application is behind a reverse proxy. 

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

See further documentation for `SocketAddress` [here](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
