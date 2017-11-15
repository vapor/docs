# Routing

In Vapor, routing is usually done using the `.get`, `.put`, `.post`, `.patch` and `.delete` shorthands. You can provide [custom (flexible) parameters](../routing/parameters.md) or normal literal string path components to express the path.

## Creating a router

To register routes, first, you need to get a router object.

To access some routing functions you may need to `import Routing`.

```swift
let router = try app.make(Router.self)
```

This router can then be used to register routes. However, you should only register routes during the setup phase of your application. Registering routes during the execution of Vapor *could* cause a crash.

## Registering routes

Registering routes using the shorthands requires a `Router`. To work with [`Request`](../http/request.md) and [`Response`](../http/response.md) objects you should `import HTTP`.

```swift
router.get("users") { request in
    return Response(status: .ok)
}
```

We created a `GET` route to `/users/`. The [request](../http/request.md) that is accepted in the trailing closure can be used to access all request metadata.

The [`Response`](../http/response.md) returned will then be sent to the client.

The returned response in this closure **must** be either a `Response` or a [`Future`](../async/promise-future-introduction.md) containing any [`ResponseRepresentable`](../http/repsonse.md#responserepresentable).

## Registering with parameters

TODO
