# Routes

A route specifies a request handler for a given HTTP method and URI path. It can also store additional metadata.

## Methods

Routes can be registered directly to your `Application` using various HTTP method helpers. 

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

Route handlers support returning anything that is `ResponseEncodable`. This includes `Content` and any `EventLoopFuture`'s where the future value is `ResponseEncodable`.

You can specify the return type of a route using `-> T` before `in`. This can be useful in situations where the compiler cannot determine the return type.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

These are the supported route helper methods:

- `get`
- `post`
- `patch`
- `put`
- `delete`

In addition to the HTTP method helpers, there is an `on` function that accepts HTTP method as an input parameter. 

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

## Path Component

Each route registration method accepts a variadic list of `PathComponent`. This type is expressible by string literal and has four cases:

- Constant (`foo`)
- Parameter (`:foo`)
- Anything (`:`)
- Catchall (`*`)

### Constant

This is a static route component. Only requests with an exactly matching string at this position will be permitted. 

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

### Parameter

This is a dynamic route component. Any string at this position will be allowed. A parameter path component is specified with a `:` prefix. The string following the `:` will be used as the parameter's name. You can use the name to later fetch the parameters value from the request.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

### Anything

This is very similar to parameter except the value is discarded. This path component is specified as just `:`. 

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":", "baz") { req in
	...
}
```

### Catchall

This is a dynamic route component that matches one or more components. It is specified using just `*`. Any string at this position or later positions will be allowed in the request. 

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "*") { req in 
    ...
}
```

## Parameters

When using a parameter path component (prefixed with `:`), the value of the URI at that position will be stored in `req.parameters`. You can use the name of the path component to access the value. 

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    We can be sure that `req.parameters.get` will never return `nil` here since our route path includes `:name`. However, if you are accessing route parameters in middleware or in code triggered by multiple routes, you will want to handle the possibility of `nil`.


`req.parameters` also supports casting the parameter to `LosslessStringConvertible` types automatically. 

```swift
// responds to GET /hello/42
// responds to GET /hello/1337
// ...
app.get("number", ":x") { req -> String in 
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

## Body Streaming

When registering a route using the `on` method, you can specify how the request body should be handled. By default, the request body is collected into memory before calling your handler. This is useful since it allows for request content decoding to be synchronous. However, for large requests like file uploads this can potentially strain your system memory. 

To change how the request body is handled, use the `body` parameter when registering a route. There are two methods:

- `collect`: Collects the request body into memory
- `stream`: Streams the request body

```swift
app.on(.POST, "file-upload", body: .stream) { req in
    ...
}
```

When the request body is streamed, `req.body.data` will be `nil`. You must use `req.body.drain` to handle each chunk as it is sent to your route. 

## Viewing Routes

You can access your application's routes by making the `Routes` service or using `app.routes`. 

```swift
print(app.routes.all) // [Route]
```

Vapor also ships with a `routes` command that prints all available routes in an ASCII formatted table. 

```sh
$ swift run Run routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello/        |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

## Metadata

All route registration methods return the created `Route`. This allows you to metadata to the route's `userInfo` dictionary. There are some default methods available, like adding a description.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```