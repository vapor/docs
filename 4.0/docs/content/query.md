# Query

Vapor's Content APIs support handling URL encoded data in the URL's query string. 

## Decoding

To understand how decoding a URL query string works, take a look at the follow example request.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

Just like the APIs for handling HTTP message body content, the first step for parsing URL query strings is to create a `struct` that matches the expectd structure.

```swift
struct Hello: Content {
	var name: String?
}
```

Note that `name` is an optional `String` since URL query strings should always be optional. If you want to require a parameter, use a route parameter instead.

Now that you have a `Content` struct for this route's expected query string, you can decode it.

```swift
app.get("hello") { req -> String in 
	let hello = try req.query.decode(Hello.self)
	return "Hello, \(hello.name ?? "Anonymous")"
}
```

This route would result in the following response given the example request from above:

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

If the query string were omitted, like in the following request, the name "Anonymous" would be used instead.

```http
GET /hello HTTP/1.1
content-length: 0
```

## Single Value

In addition to decoding to a `Content` struct, Vapor also supports fetching single values from the query string using subscripts.

```swift
let name: String? = req.query["name"]
```

