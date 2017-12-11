# Routing

Routing is the process of finding the appropriate response to an incoming request.
For example, imagine you want to return a list of users when someone visits `GET /users`. 
That would look something like this.

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
            return "Hello, world!"
        }
    }
}
```

You can return anything that conforms to [`Content`](content.md) in a route closure. This includes [futures](futures.md) 
whose expectation is Content as well.

## Parameters

Sometimes you may want one of the components of your route path to be dynamic. This is often used when
you want to get an item with a supplied identifier, i.e., `GET /users/:id`

```swift
router.get("users", Int.self) { req in
    let id = try req.parameters.next(Int.self)
    return // fetch the user with id
}
```

Instead of passing a string, pass the _type_ of parameter you expect. In this case, our `User` has an `Int` ID.

!!! tip
    You can define your own [custom parameter types](../routing/parameters.md) as well.
