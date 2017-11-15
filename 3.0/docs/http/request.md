# Request

When a client connects with an HTTP Server it sends a `Request`. This HTTP request will be processed [as discussed here](../getting-started/http.md) and resolved into a [`Response`](response.md). This is the response in the http [Request/Response model](../getting-started/http.md).

Requests consist of a [Method](method.md), [URI](uri.md) and [Headers](../web/headers.md).

Requests can optionally also contain a [Body](body.md).

Requests are Extensible using the `extend` property. This allow storing additional data for use by integrating libraries.

## Request properties

Request has a few primary properties according to spec, and one extra property as part of the Vapor framework.

The [Request Method](method.md), [URI](uri.md), [Headers](headers.md) and [Body](body.md) are available.

We also provide access to the HTTP version, although this will almost always be `1.1`.

In addition to these properties there is an Extend available which an be used to store extra information for each request.

It can be used to store information between [middlewares](middleware.md) and the responder and is used by Vapor to store the current [Worker](../async/worker.md), too.

Using Extend, many properties can be added in extensions.

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
