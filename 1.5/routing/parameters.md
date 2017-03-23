---
currentMenu: routing-parameters
---

# Routing Parameters

Traditional web frameworks leave room for error in routing by using strings for route parameter names and types. Vapor takes advantage of Swift's closures to provide a safer and more intuitive method for accessing route parameters.

## Type Safe

To create a type safe route simply replace one of the parts of your path with a `Type`.

```swift
drop.get("users", Int.self) { request, userId in
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

## String Initializable

Any type that conforms to `StringInitializable` can be used as a type-safe routing parameter. By default, the following types conform:

- String
- Int
- Model

`String` is the most generic and always matches. `Int` only matches when the string supplied can be turned into an integer. `Model` only matches when the string, used as an identifier, can be used to find the model in the database.

Our previous example with users can be further simplified.

```swift
drop.get("users", User.self) { request, user in
  return "You requested \(user.name)"
}
```

Here the identifier supplied is automatically used to lookup a user. For example, if `/users/5` is requested, the `User` model will be asked for a user with identifier `5`. If one is found, the request succeeds and the closure is called. If not, a not found error is thrown.

Here is what this would look like if model didn't conform to `StringInitializable`.

```swift
drop.get("users", Int.self) { request, userId in
  guard let user = try User.find(userId) else {
    throw Abort.notFound
  }

    return "You requested User #\(userId)"
}
```

Altogether, type safe routing can save around 6 lines of code from each route.

### Protocol

Conforming your own types to `StringInitializable` is easy.

```swift
public protocol StringInitializable {
    init?(from string: String) throws
}
```

Here is what `Model`'s conformance looks like for those who are curious.

```swift
extension Model {
    public init?(from string: String) throws {
        if let model = try Self.find(string) {
            self = model
        } else {
            return nil
        }
    }
}
```

The `init` method can both `throw` and return `nil`. This allows you to `throw` your own errors. Or, if you want the default error and behavior, just return `nil`.

### Limits

Type safe routing is currently limited to three path parts. This is usually remedied by adding route [groups](group.md).

```swift
drop.group("v1", "users") { users in
  users.get(User.self, "posts", Post.self) { request, user, post in
    return "Requested \(post.name) for \(user.name)"
  }
}
```

The resulting path for the above example is `/v1/users/:userId/posts/:postId`. If you are clamoring for more type safe routing, please let us know and we can look into increasing the limit of three.

## Manual

As shown briefly above, you are still free to do traditional routing. This can be useful for especially complex situations.

```swift
drop.get("v1", "users", ":userId", "posts", ":postId", "comments", ":commentId") { request in
  let userId = try request.parameters.extract("userId") as Int
  let postId = try request.parameters.extract("postId") as Int
  let commentId = try request.parameters.extract("commentId") as Int

  return "You requested comment #\(commentId) for post #\(postId) for user #\(userId)"
}
```

> Property `request.parameters` is used to extract parameters encoded in the URI _path_ (for example, `/v1/users/1` has a parameter `:userId` equal to `"1"`). In case of parameters passed as a part of a _query_ (e.g. `/v1/search-user?userId=1`), the `request.data` should be used (e.g. `let userId = request.data["userId"]?.string`).

Request parameters can be accessed either as a dictionary or using the `extract` syntax which throws instead of returning an optional.

### Groups

Manual request parameters also work with [groups](group.md).

```swift
let userGroup = drop.grouped("users", ":userId")
userGroup.get("messages") { req in
    let user = try req.parameters.extract("userId") as User
}
```
