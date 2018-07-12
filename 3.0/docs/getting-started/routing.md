# Routing

Routing is the process of finding the appropriate response to an incoming request.

## Making a Router

In Vapor the default Router is the `EngineRouter`. You can implement custom routers by implementing one conforming to the `Router` protocol.

```swift
let router = try EngineRouter.default()
```

This is usually done in your [`configure.swift`](structure.md#configureswift) file.

## Registering a route

Imagine you want to return a list of users when someone visits `GET /users`. Leaving authorization aside, that would look something like this.

```swift
router.get("users") { req in
    return // fetch the users
}
```

In Vapor, routing is usually done using the `.get`, `.put`, `.post`, `.patch` and `.delete` shorthands. You can supply the path as `/` or comma-separated strings. We recommend comma separated, as it's more readable.

```swift
router.get("path", "to", "something") { ... }
```

## Routes

The best place to add routes is in the [`routes.swift`](structure.md#routesswift) file. Use the router supplied as a parameter to this function to register your routes.

```swift
import Vapor

public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
  
    /// ...
}
```

See [Getting Started &rarr; Content](content.md) for more information about what can be returned in a route closure.

## Parameters

Sometimes you may want one of the components of your route path to be dynamic. This is often used when
you want to get an item with a supplied identifier, e.g., `GET /users/:id`

```swift
router.get("users", Int.parameter) { req -> String in
    let id = try req.parameters.next(Int.self)
    return "requested id #\(id)"
}
```

Instead of passing a string, pass the _type_ of parameter you expect. In this case, our `User` has an `Int` ID.

!!! tip
    You can define your own [custom parameter types](../routing/overview.md#parameter) as well.

## After registering your routes

After registering your routes you must register the Router as a [Getting Started &rarr; Services](services.md)
