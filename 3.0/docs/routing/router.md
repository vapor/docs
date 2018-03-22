# Router

Router is a protocol that you can conform your own routers to.

## Registering a route

First, create a [Route](route.md) using a HTTP method, path and a responder.

The following example shows a route with a constant path.

```swift
let responder = BasicAsyncResponder { request in
  return "Hello world"
}

let route = Route(method: .get, path: [.constant("hello"), .constant("world")], responder: responder)
```

The following example shows a with a [Parameter](parameters.md):

```swift
let responder = BasicSyncResponder { request in
  let name = try request.parameter(String.self)
  return "Hello \(name)"
}

let route = Route(method: .get, path: [.constant("greet"), .parameter(String.self)], responder: responder)
```

## Routing a request through a Router

Assuming you have a request, like the following example:

```swift
let request = Request(method: .get, URI(path: "/hello/world"))
```

The router should be able to route the HTTP request using

```swift
let responder = router.route(request: request)
```
