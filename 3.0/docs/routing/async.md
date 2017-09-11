# Asynchronous routing

The `AsyncRouter` protocol can be applied on top of any router without additional implementation.

```swift
let router: AsyncRouter = ...
```

## Registering a route

The `on` function on a `AsyncRouter` registers a route to the provided path. The following registers a `GET /hello/world` route.

It responds with `"Hello world!"`

```swift
router.on(.get, to: "hello", "world") { request in
  return "Hello world!"
}
```

The `.get` represents the [Method](../http/method.md) you want to use. `to: "hello", "world"` registers the path `/hello/world`.

The trailing closure receives a [Request](../http/request.md). The route can throw errors and needs to return a [`Future<ResponseRepresentable>`](../vapor/response.md) conforming type.
