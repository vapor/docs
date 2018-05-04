# Using Sessions

This guide will show you how to use sessions in Vapor to maintain state for a connected client.

Sessions work by creating unique identifiers for each new client and asking the client to supply this identifier with each request. When the next request is received, Vapor uses this unique identifier to restore the session data. This identifier could be transmitted in any format, but it is almost always done with cookies and that is how Vapor's sessions work. 

When a new client connects and session data is set, Vapor will return a `Set-Cookie` header. The client is then expected to re-supply the value with each request in a `Cookie` header. All browsers do this automatically. If your ever decide to invalidate the session, Vapor will delete any related data and notify the client that their cookie is no longer valid.

## Middleware

The first step to using sessions is enabling [`SessionsMiddleware`](https://api.vapor.codes/vapor/latest/Vapor/Classes/SessionsMiddleware.html). This can be done globally for the entire application or on a per-route basis.

### Globally

To globally enable sessions, add the middleware to your [`MiddlewareConfig`](https://api.vapor.codes/vapor/latest/Vapor/Structs/MiddlewareConfig.html).


```swift
var middlewares = MiddlewareConfig.default()
middlewares.use(SessionsMiddleware.self)
services.register(middlewares)
```

This is usually done in [`configure.swift`](../getting-started/structure.md#configureswift).

### Per Route

To enable sessions for a group of routes, use the [`grouped(...)`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Router.html) methods on `Router`.

```swift
// create a grouped router at /sessions w/ sessions enabled
let sessions = router.grouped("sessions").grouped(SessionsMiddleware.self)

// create a route at GET /sessions/foo
sessions.get("foo") { req in
	// use sessions
}
```

## Sessions

When `SessionsMiddleware` boots it will attempt to make a [`Sessions`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Sessions.html) and a [`SessionsConfig`](https://api.vapor.codes/vapor/latest/Vapor/Structs/SessionsConfig.html). Vapor will use an in-memory session by default. You can override both of these services by registering them in `configure.swift`.

You can use Fluent databases (like MySQL, PostgreSQL, etc) or caches like Redis to store your sessions. See the respective guides for more information.

## Session

Once you have `SessionsMiddleware` enabled, you can use [`req.session()`](https://api.vapor.codes/vapor/latest/Vapor/Classes/Request.html#/s:5Vapor7RequestC7sessionAA7SessionCyKF) to access the session. Here is a simple example that does simple CRUD operations on a `"name"` value in the session.

```swift
// create a route at GET /sessions/get
sessions.get("get") { req -> String in
	// access "name" from session or return n/a
    return try req.session()["name"] ?? "n/a"
}

// create a route at GET /sessions/set/:name
sessions.get("set", String.parameter) { req -> String in
	// get router param
    let name = try req.parameters.next(String.self)

    // set name to session at key "name"
    try req.session()["name"] = name

    // return the newly set name
    return name
}

// create a route at GET /sessions/del
sessions.get("del") { req -> String in
	// destroy the session
    try req.destroySession()

    // signal success
    return "done"
}
```

That's it, congratulations on getting sessions working!
