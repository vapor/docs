# Basics

In Vapor the default Router is the `EngineRouter`. You can implement custom routers by implementing one conformant to the `Router` protocol.

```swift
let router = try EngineRouter.default()
```

There are two APIs available, one is supplied by the `Routing` library and a set of helpers is available in Vapor itself.

## Registering a route using Routing

The `on` function on a `AsyncRouter` registers a route to the provided path. The following registers a `GET /hello/world` route.

It responds with `"Hello world!"` using futures.

```swift
router.on(.get, to: "hello", "world") { request in
  return try Response(body: "Hello world!")
}
```

The `.get` represents the Method you want to use. `to: "hello", "world"` registers the path `/hello/world`.

For variable path components you can use [parameters](parameters.md).

The trailing closure receives a Request. The route can throw errors and needs to return a [`Future<ResponseRepresentable>`](../http/response.md) conforming type.

## Registering a route using Vapor

In Vapor we add support for routes using the `.get`, `.put`, `.post`, `.patch` and `.delete` shorthands.

For variable path components you can use [parameters](parameters.md) here, too.

Vapor has an added benefit here in that you can return the `Response` itself in addition to `Future<ResponseRepresentable>` or `Future<Response>`.

```swift
router.get("components", "in", "path") { request in
  return Response(status: .ok)
}
```

## After registering your routes

After registering routes to the Router, you must add the router to your services.

```swift
services.instance(Router.self, router)
```

[More about services here.](../concepts/services.md)
