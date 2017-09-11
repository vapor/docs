# Responder

Responders are a type capable of [responding](response.md) to a [Request](request.md).

Responders are always [async](../async/promise-future.md) by returning a `Future<Response>` by either transforming/mapping an existing future or creating it's own promise.

## Implementing a static Responder

```swift
struct StaticResponder: Responder {
  let response: Response

  init(response: Response) {
    self.response = response
  }

  func respond(to req: Request) throws -> Future<Response> {
    return Future(response)
  }
}
```
