# Response

When a client connects with an HTTP Server it sends a [`Request`](request.md). This HTTP request will be processed [as discussed here](../concepts/http.md) and resolved into a `Response`. This is the response in the http Request/Response model.

HTTP's Response object contains a [Status](status.md), [Headers](headers.md) and a [Body](body.md). Before further reading this page, you must have read and understood the previous pages for Status, Headers and Body.

Responses are Extensible using the `extend` property. This allow storing additional data for use by integrating libraries.

## Creating a Response

A Response accepts a version, status, headers and body. The version's default is recommended. The body is optional.

The body can be an `HTTPBody` or `HTTPBodyRepresentable`. If the body is a `HTTPBodyRepresentable` the `Response` initializer will become throwing.

```swift
let response1 = Response(
                  status: status,
                  headers: headers,
                  body: body
                )

let response2 = try Response(
                  status: status,
                  headers: headers,
                  body: bodyRepresentable
                )
```

### Low level APIs

`Response` is a wrapper around the lower level `HTTPResponse`. `Response` adds better integration with Vapor 3's async, services and related frameworks.
