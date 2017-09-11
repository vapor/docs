# Request

When a client connects with an HTTP Server it sends a `Request`. This HTTP request will be processed [as discussed here](../getting-started/http-request-response.md) and resolved into a [`Response`](response.md). This is the response in the http Request/Response model.

Requests consist of a [Method](method.md), [URI](uri.md) and [Headers](../web/headers.md).

Requests can optionally also contain a Body.

[Requests are Extensible.](../core/extend.md)

## Accessing Request information



## Creating a Request

Creating requests is necessary for [HTTP Clients](client.md).

A request accepts a method, uri, version, headers and body. The version's default is recommended. The body is optional.

The body can be a `Body` or `BodyRepresentable`. If the body is a `BodyRepresentable` the `Response` initializer will become throwing.

```swift
let request1 = Request(
                method: .get,
                uri: uri,
                headers: headers,
                body: body
              )

let request2 = try Request(
                method: .get,
                uri: uri,
                headers: headers,
                body: bodyRepresentable
              )
```
