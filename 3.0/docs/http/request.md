# Request

When a client connects with an HTTP Server it sends a `Request`. This HTTP request will be processed [as discussed here](../concepts/http.md) and resolved into a [`Response`](response.md). This is the response in the http [Request/Response model](../concepts/http.md).

Requests consist of a [Method](method.md), [URI](uri.md) and [Headers](headers.md).

Requests can optionally also contain a [Body](body.md).

Requests are Extensible using the `extend` property. This allow storing additional data for use by integrating libraries.

## Request properties

Request has a few primary properties according to spec.
The [Request Method](method.md), [URI](uri.md), [Headers](headers.md) and [Body](body.md) are available.

We also provide access to the HTTP version, although this will almost always be `1.1`.

Besides this, `Request` is a [`Container`](../services/getting-started.md) type, so it can be used as a frame of reference to `make` a new service.

## Creating a Request

Creating requests is necessary for [HTTP Clients](client.md).

A request accepts a method, uri, version, headers and body. The version's default is recommended. The body is optional.

The body can be a `HTTPBody` or `HTTPBodyRepresentable`. If the body is a `HTTPBodyRepresentable` the `Request` initializer will become throwing.

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

### Low level APIs

`Request` is a wrapper around the lower level `HTTPRequest`. `Request` adds better integration with Vapor 3's async, services and related frameworks.
