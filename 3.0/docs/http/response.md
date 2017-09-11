# HTTP Response

When a client connects with an HTTP Server it sends a [`Request`](request.md). This HTTP request will be processed [as discussed here](../getting-started/http-request-response.md) and resolved into a `Response`. This is the response in the http Request/Response model.

HTTP's Response object contains a [Status](status.md), [Headers](../web/headers.md) and a [Body](body.md). Before further reading this page, you must have read and understood the previous pages for Status, Headers and Body.

[Responses are Extensible.](../core/extend.md)

## Creating a Response

A Response accepts a version, status, headers and body. The version's default is recommended. The body is optional.

The body can be a `Body` or `BodyRepresentable`. If the body is a `BodyRepresentable` the `Response` initializer will become throwing.

```swift
let response1 = Response(
                  status: status,
                  headers: headers,
                  body: body)

let response2 = try Response(
                  status: status,
                  headers: headers,
                  body: bodyRepresentable)
```

## ResponseRepresentable

Instead of requiring a Response, many parts of the framework and related libraries work with the protocol `ResponseRepresentable`. When types conform to `ResponseRepresentable` they're required to implement a `makeResponse` function that allows conversion from this instance to a `Response`.

For the purpose of an example, we'll convert an integer to a `Response`. This `Int` will always response with a status code 200 (OK) and a body containing itself in textual representation.

```swift
extension Int: ResponseRepresentable {
  public func makeResponse() throws -> Response {
    return try Response(status: .ok, body: self.description)
  }
}
```

## ResponseInitializable

`ResponseInitializable` is used for converting a `Response` to another type.

This is particularely useful for [HTTP Clients](client.md) that interact with existing APIs.

This example is pseudocode for interacting with a payment API such as Stripe or PayPal in a type-safe fashion.

```swift
struct PaymentStatus: ResponseInitializable {
  public init(response: Response) throws {
    // Create a `PaymentStatus` from the API call's `Response`
  }
}
```
