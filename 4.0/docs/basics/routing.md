# Routing

Routing is the process of finding the appropriate request handler for an incoming request. At the core of Vapor's routing is a high-performance, trie-node router from [RoutingKit](https://github.com/vapor/routing-kit).

## Overview 

To understand how routing works in Vapor, you should first understand a few basics about HTTP requests. Take a look at the following example request.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

This is a simple `GET` HTTP request to the URL `/hello/vapor`. This is the kind of HTTP request your browser would make if you pointed it to the following URL.

```
http://vapor.codes/hello/vapor
```

### HTTP Method

The first part of the request is the HTTP method. `GET` is the most common HTTP method, but there are several you will use often. These HTTP methods are often associated with [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) semantics.

|method|crud|
|-|-|
|`GET`|Read|
|`POST`|Create|
|`PUT`|Replace|
|`PATCH`|Update|
|`DELETE`|Delete|

### Request Path

Right after the HTTP method is the request's URI. This consists of a path starting with `/` and an optional query string after `?`. The HTTP method and path are what Vapor uses to route requests.

After the URI is the HTTP version followed by zero or more headers and finally a body. Since this is a `GET` request, it does not have a body. 

### Router Methods

Let's take a look at how this request could be handled in Vapor. 

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

All of the common HTTP methods are available as methods on `Application`. They accept one or more string arguments that represent the request's path separated by `/`. 

Note that you could also write this using `on` followed by the method.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

With this route registered, the example HTTP request from above will result in the following HTTP response.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Route Parameters

Now that we've successfully routed a request based on the HTTP method and path, let's try making the path dynamic. Notice that the name "vapor" is hardcoded in both the path and the response. Let's make this dynamic so that you can visit `/hello/<any name>` and get a response.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

By using a path component prefixed with `:`, we indicate to the router that this is a dynamic component. Any string supplied here will now match this route. We can then use `req.parameters` to access the value of the string.

If you run the example request again, you'll still get a response that says hello to vapor. However, you can now include any name after `/hello/` and see it included in the response. Let's try `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

Now that you understand the basics, check out each section to learn more about parameters, groups, and more.

## Routes

A route specifies a request handler for a given HTTP method and URI path. It can also store additional metadata.

### Methods

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

### Path Component

Each route registration method accepts a variadic list of `PathComponent`. This type is expressible by string literal and has four cases:

- Constant (`foo`)
- Parameter (`:foo`)
- Anything (`:`)
- Catchall (`*`)

#### Constant

This is a static route component. Only requests with an exactly matching string at this position will be permitted. 

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parameter

This is a dynamic route component. Any string at this position will be allowed. A parameter path component is specified with a `:` prefix. The string following the `:` will be used as the parameter's name. You can use the name to later fetch the parameters value from the request.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Anything

This is very similar to parameter except the value is discarded. This path component is specified as just `:`. 

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":", "baz") { req in
	...
}
```

#### Catchall

This is a dynamic route component that matches one or more components. It is specified using just `*`. Any string at this position or later positions will be allowed in the request. 

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "*") { req in 
    ...
}
```

### Parameters

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

### Body Streaming

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

### Viewing Routes

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

### Metadata

All route registration methods return the created `Route`. This allows you to metadata to the route's `userInfo` dictionary. There are some default methods available, like adding a description.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## Route Groups

Route grouping allows you to create a set of routes with a path prefix or specific middleware. Grouping supports a builder and closure based syntax.

All grouping methods return a `RouteBuilder` meaning you can infinitely mix, match, and nest your groups with other route building methods.

### Path Prefix

Path prefixing route groups allow you to prepend one or more path components to a group of routes. 

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Any path component you can pass into methods like `get` or `post` can be passed into `grouped`. There is an alternative, closure-based syntax as well.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

Nesting path prefixing route groups allows you to concisely define CRUD APIs.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### Middleware

In addition to prefixing path components, you can also add middleware to route groups. 

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```


This is especially useful for protecting subsets of your routes with different authentication middleware. 

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```
