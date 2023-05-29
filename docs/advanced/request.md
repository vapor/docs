# Request

The [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) object is passed into every [route handler](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

It is the main window into the rest of Vapor's functionality. It contains APIs for the [request body](../basics/content.md), [query parameters](../basics/query.md), [logger](../basics/logging.md), [HTTP client](../basics/client.md), and more. Accessing this functionality through the request keeps computation on the correct event loop and allows it to be mocked for testing.

## Application

The `Request.application` property holds a reference to the [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). This object contains all of the configuration and core functionality for the application. Much of it should only be set in `configure.swift` before the application fully starts, and many of the lower level APIs won't be needed in most applications. One of the most useful properties is `Application.eventLoopGroup` which can be used to get an `EventLoop` for processes that need a new one via the `next()` method. It also contains the [`Environment`](../basics/environment.md).

## Authentication

Once you have set up an [authentication strategy](../security/authentication.md), `Request.auth.require()` can be used to get the object associated with the authenticator for the route.

```swift
let authenticated = app.grouped(User.authenticator())
authenticated.get("me") { req -> User in
    return try req.auth.require(User.self)
}
```

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


