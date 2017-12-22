# Routing

Routing is the process of finding the appropriate response to an incoming request.

## Making a Router

In Vapor the default Router is the `EngineRouter`. You can implement custom routers by implementing one conformant to the `Router` protocol.

```swift
let router = try EngineRouter.default()
```

There are two APIs available, one is supplied by the `Routing` library and a set of helpers is available in Vapor itself.

We recommend using the helpers and will continue to describe those here.

## Registering a route

Imagine you want to return a list of users when someone visits `GET /users`.
Leaving authorization on the side, that would look something like this.

```swift
router.get("users") { req in
    return // fetch the users
}
```

In Vapor, routing is usually done using the `.get`, `.put`, `.post`, `.patch` and `.delete` shorthands.
You can supply the path as `/` or comma-separated strings. We recommend comma separated, as it's more readable.

```swift
router.get("path", "to", "something") { ... }
```

## Routes

The best place to add routes is in the [`routes.swift`](structure.md#routesswift) file.
You will find a router there that is ready to use.

```swift
import Vapor

final class Routes: RouteCollection {
    ...

    func boot(router: Router) throws {
        router.get("hello") { req in
            return Future("Hello, world!")
        }
    }
}
```

You _must_ return a Future containing a `ResponseEncodable` here.
The most common `ResponseEncodable` types are [`Content`](content.md), [`Response`](../http/response.md) amd [`View`](../leaf/view.md).

## Parameters

Sometimes you may want one of the components of your route path to be dynamic. This is often used when
you want to get an item with a supplied identifier, i.e., `GET /users/:id`

```swift
router.get("users", Int.parameter) { req -> Future<String> in
    let id = try req.parameter(Int.self)
    return // fetch the user with id
}
```

Instead of passing a string, pass the _type_ of parameter you expect. In this case, our `User` has an `Int` ID.

!!! tip
    You can define your own [custom parameter types](../routing/parameters.md) as well.

## After registering your routes

After registering your routes you must register the Router as a [`Service`](../concepts/services.md)
