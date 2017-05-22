# Routing Parameters

Traditional web frameworks leave room for error in routing by using strings for route parameter names and types. Vapor takes advantage of Swift's closures to provide a safer and more intuitive method for accessing route parameters.

!!! seealso
    Route parameters refer to segments of the URL path (e.g., `/users/:id`). For query parameters (e.g., `?foo=bar`) see [request query parameters](../http/request/#query-parameters).

## Type Safe

To create a type safe route simply replace one of the parts of your path with a `Type`.

```swift
drop.get("users", Int.parameter) { req in
    let userId = try req.parameters.next(Int.self)
    return "You requested User #\(userId)"
}
```

This creates a route that matches `users/:id` where the `:id` is an `Int`. Here's what it would look like using manual route parameters.

```swift
drop.get("users", ":id") { request in
    guard let userId = request.parameters["id"]?.int else {
        throw Abort.badRequest
    }

    return "You requested User #\(userId)"
}
```

Here you can see that type safe routing saves ~3 lines of code and also prevents runtime errors like misspelling `:id`.

## Parameterizable

Any type conforming to `Parameterizable` can be used as a parameter. By default, all Vapor [Models](../fluent/model.md) conform.

Using this, our previous example with users can be further simplified.

```swift
drop.get("users", User.parameter) { req in
    let user = try req.parameters.next(User.self)

    return "You requested \(user.name)"
}
```

Here the identifier supplied is automatically used to lookup a user. For example, if `/users/5` is requested, the `User` model will be asked for a user with identifier `5`. If one is found, the request succeeds and the closure is called. If not, a not found error is thrown.

Here is what this would look like if we looked the model up manually.

```swift
drop.get("users", Int.parameter) { req in
    let userId = try req.parameters.next(Int.self)
    guard let user = try User.find(userId) else {
        throw Abort.notFound
    }

    return "You requested \(user.name)"
}
```

### Protocol

You can conform your own types to `Parameterizable`.

```swift
import Routing

extension Foo: Parameterizable {
    /// This unique slug is used to identify
    /// the parameter in the router
    static var uniqueSlug: String {
        return "foo"
    }


    static func make(for parameter: String) throws -> Foo {
        /// custom lookup logic here
        /// the parameter string contains the information
        /// parsed from the URL.
        ...
    }
}
```

Now you can use this type for type safe routing.

```swift
drop.get("users", "nickname", Foo.parameter) { req in
    let foo = try req.parameters.next(Foo.self)
    ...
}
```

### Groups

Type-safe parameters also work with [groups](group.md).

```swift
let userGroup = drop.grouped("users", User.parameter)
userGroup.get("messages") { req in
    let user = try req.parameters.next(User.self)

    ...
}
```
