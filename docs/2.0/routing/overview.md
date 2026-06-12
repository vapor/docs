# Basic Routing

Routing is one of the most critical parts of a web framework. The router decides which requests get which responses.

Vapor has a plethora of functionality for routing including route builders, groups, and collections. In this section, we will look at the basics of routing.

## Register

The most basic route includes a method, path, and closure.

```swift
drop.get("welcome") { request in
    return "Hello"
}
```

The standard HTTP methods are available including `get`, `post`, `put`, `patch`, `delete`, and `options`.

```swift
drop.post("form") { request in
    return "Submitted with a POST request"
}
```

## Nesting

To nest paths (adding `/`s in the URL), simply add commas.

```swift
drop.get("foo", "bar", "baz") { request in
    return "You requested /foo/bar/baz"
}
```

You can also use `/`, but commas are often easier to type and work better with type safe route [parameters](parameters.md).

## Alternate

An alternate syntax that accepts a `Method` as the first parameter is also available.

```swift
drop.add(.trace, "welcome") { request in
    return "Hello"
}
```

This may be useful if you want to register routes dynamically or use a less common method.

## Request

Each route closure is given a single [Request](../http/request.md). This contains all of the data associated with the request that led to your route closure being called.

## Response Representable

A route closure can return in three ways:

- `Response`
- `ResponseRepresentable`
- `throw`

### Response

A custom [Response](../http/response.md) can be returned.

```swift
drop.get("vapor") { request in
    return Response(redirect: "http://vapor.codes")
}
```

This is useful for creating special responses like redirects. It is also useful for cases where you want to add cookies or other items to the response.

### Response Representable

As you have seen in the previous examples, `String`s can be returned in route closures. This is because they conform to [ResponseRepresentable](../http/response-representable.md)

A lot of types in Vapor conform to this protocol by default:
- String
- Int
- [JSON](../json/package.md)
- [Model](../fluent/model.md)

```swift
drop.get("json") { request in
    var json = JSON()
    try json.set("number", 123)
    try json.set("text", "unicorns")
    try json.set("bool", false)
    return json
}
```

### Throwing

If you are unable to return a response, you may `throw` any object that conforms to `Error`. Vapor comes with a default error enum `Abort`.

```swift
drop.get("404") { request in
    throw Abort(.notFound)
}
```

You can customize the message of these errors by using `Abort`

```swift
drop.get("error") { request in
    throw Abort(.badRequest, reason: "Sorry 😱")
}
```

These errors are caught by default in the `ErrorMiddleware` where they are turned into a JSON response like the following.

```json
{
    error: true,
    message: "<the message>"
}
```

If you want to override this behavior, remove the `ErrorMiddleware` (key: `"error"`) from the `Droplet`'s middleware and add your own.

## Fallback

Fallback routes allow you to match multiple layers of nesting slashes.

```swift
app.get("anything", "*") { request in
    return "Matches anything after /anything"
}
```

For example, the above route matches all of the following and more:

- /anything
- /anything/foo
- /anything/foo/bar
- /anything/foo/bar/baz
- ...
