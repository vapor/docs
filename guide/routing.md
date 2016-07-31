---
currentMenu: guide-routing
---

# Routing

Routes in Vapor can be defined in any file that has access to your instance of `Droplet`. This is usually in the `main.swift` file.

## Basic

The most basic route includes a method, path, and closure.

```swift
drop.get("welcome") { request in 
    return "Hello"
}
```

The standard HTTP methods are available including `get`, `post`, `put`, `patch`, `delete`, and `options`.

You can also use `any` to match all methods.

## Request

The first parameter passed into your route closure is an instance of [Request](request.md). This contains the method, URI, body, and more.

```swift
let method = request.method
```

When you add a parameter type, like `String.self`, the closure will be required to contain another input variable. This variable will be the same type. In this case, `String`.

## JSON

To respond with JSON, simply wrap your data structure with `JSON(node: )`

```swift
drop.get("version") { request in
    return try JSON(node: ["version": "1.0"])
}
```

## Response Representable

All routing closures can return a [ResponseRepresentable](response.md) data structure. By default, Strings and JSON conform to this protocol, but you can add your own.

```swift
public protocol ResponseRepresentable {
    func makeResponse() throws -> Response
}
```

## Parameters

Parameters are described by passing the type of data you would like to receive.

```swift
drop.get("hello", String.self) { request, name in 
    return "Hello \(name)"
}
```

## String Initializable

Any type that conforms to `StringInitializable` can be used as a parameter. By default, `String` and `Int` conform to this protocol, but you can add your own.

```swift
struct User: StringInitializable {
    ...
}

app.get("users", User.self) { request, user in 
    return "Hello \(user.name)"
}
```

Using Swift extensions, you can extend your existing types to support this behavior.

```swift
extension User: StringInitializable {
    init?(from string: String) throws {
        guard let int = Int(string) else {
            return nil //Will Abort.InvalidRequest
        }

        guard let user = User.find(int) else {
            throw UserError.NotFound
        }

        self = user
    }
}
```

You can throw your own errors or return `nil` to throw the default error.

## Groups

Prefix a group of routes with a common string, host, or middleware using `group` and `grouped`.

### Group

Group (without the "ed" at the end) takes a closure that is passed a `GroupBuilder`.

```swift
drop.group("v1") { v1 in
    v1.get("users") { request in
        // get the users
    }
}
```

### Grouped

Grouped returns a `GroupBuilder` that you can pass around.

```swift
let v1 = drop.grouped("v1")
v1.get("users") { request in
    // get the users
}
```

### Middleware

You can add middleware to a group of routes. This is especially useful for authentication.

```swift
drop.group(AuthMiddleware()) { authorized in 
    authorized.get("token") { request in
        // has been authorized
    }
}
```

### Host

You can limit the host for a group of routes.

```
drop.group(host: "qutheory.io") { qt
    qt.get { request in
        // only responds to requests to qutheory.io
    }
}
```

### Chaining

Groups can be chained together.

```swift
drop.grouped(host: "qutheory.io").grouped(AuthMiddleware()).group("v1") { authedSecureV1 in
    // add routes here
}
```

## Custom Routing

Vapor still supports traditional routing for custom use-cases or long URLs.

```swift
drop.get("users/:user_id") { request in
    request.parameters["user_id"] // String?
}
```
