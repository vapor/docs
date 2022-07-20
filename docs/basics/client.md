# Client

Vapor's client API allows you to make HTTP calls to external resources. It is built on [async-http-client](https://github.com/swift-server/async-http-client) and integrates with the [content](content.md) API.

## Overview

You can get access to the default client via `Application` or in a route handler via `Request`.

```swift
app.client // Client

app.get("test") { req in
	req.client // Client
}
```

The application's client is useful for making HTTP requests during configuration time. If you are making HTTP requests in a route handler, always use the request's client.

### Methods

To make a `GET` request, pass the desired URL to the `get` convenience method.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

There are methods for each of the HTTP verbs like `get`, `post`, and `delete`. The client's response is returned as a future and contains the HTTP status, headers, and body.

### Content

Vapor's [content](content.md) API is available for handling data in client requests and responses. To encode content, query parameters or add headers to the request, use the `beforeSend` closure.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Encode query string to the request URL.
	try req.query.encode(["q": "test"])

	// Encode JSON to the request body.
    try req.content.encode(["hello": "world"])
    
    // Add auth header to the request
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Handle the response.
```

You can also decode the response body using `Content` in a similar way:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

If you're using futures you can use `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
	// Use JSON here
}
```

## Configuration

You can configure the underlying HTTP client via the application.

```swift
// Disable automatic redirect following.
app.http.client.configuration.redirectConfiguration = .disallow
```

Note that you must configure the default client _before_ using it for the first time.


