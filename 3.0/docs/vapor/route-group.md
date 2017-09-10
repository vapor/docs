# Routing groups

Routing groups are used to simplify routing. A routing group can contain [middleware](../http/middleware.md) and/or path components.

## Middleware

All [Middleware](../http/middleware.md) will be appended inbetween the existing middleware chain and the responder.

```swift
let group = router.grouped(middleware0, middleware1, middlewareN)

// This registered route will pass through the following chain
// middleware0 -> middleware1 -> middlewareN -> route
group.on(.get, "hello") { request in
  return ...
}
```

Closure based syntax also works, when working with route register functions for example.

```swift
router.group(middleware0, middleware1, middlewareN) { group in
  // register routes
}
```

Like any closure, you can provide a function here

```swift
func register(to router: Router) {
  // This registered route will pass through the following chain
  // middleware0 -> middleware1 -> middlewareN -> route
  router.on(.get, "hello") { request in
    return ...
  }
}

router.group(middleware0, middleware1, middlewareN, use: register)
```

## Path components

Like the middleware chain, path components will be appended inbetween the existing components and the route.

```swift
let group = router.grouped("api", "v1")

// This registered route will be on the following path
// `GET /api/v1/hello`
group.on(.get, "hello") { request in
  return ...
}
```

The same syntax for grouping is available as with middleware.

```swift
router.group("api", "v1") { group in
  // register routes
}
```

Like any closure, you can provide a function here, just like middleware.

```swift
func register(to router: Router) {
  // This registered route will be on the following path
  // `GET /api/v1/hello`
  router.on(.get, "hello") { request in
    return ...
  }
}

router.group("api", "v1", use: register)
```

### Parameters

Parameters inside `Group`s will affect routes.

```swift
func register(to router: SyncRouter) {
  // This registered route will be on the following path
  // `GET /api/v1/\(string_here)/echo`
  //
  // Will return the `string_here` parameter
  router.on(.get, "echo") { request in
    let string_here = try request.parameters.next(String.self)

    return string_here
  }
}

router.group("api", "v1", String.parameter, use: register)
```

**WARNING**

Using parameters inside a group might have unforeseen effects:

```swift
let group = router.grouped("api", "v1", String.parameter)

group.on(.get, String.parameter) { request in
  // Expects the route specific string parameter
  // Instead gets the grouped string parameter
  let parameter = try request.parameters.next(String.self)

  ...
}
```
