---
currentMenu: routing-parameters
---

# Routing Parameters

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

传统的 web 框架在路由汇总使用字符串表示路由参数和类型，这个会很容易产生错误。Vapor 利用闭包提供更加安全直接的方法去访问路由参数。

## Type Safe

想要创建一个类型安全的路由，只需要使用 `Type` 替换你的路径中的一部分。


```swift
drop.get("users", Int.self) { request, userId in
    return "You requested User #\(userId)"
}
```

这样就创建了一个路由，用于匹配当 `:id` 是 `Int` 的 `users/:id` 路径。下面的是使用手动路由参数的例子代码：

```swift
drop.get("users", ":id") { request in
  guard let userId = request.parameters["id"]?.int else {
    throw Abort.badRequest
  }

  return "You requested User #\(userId)"
}
```

你能看到类型安全的路由只有 3 行代码，并且避免了运行时错误，比如 `:id` 拼写错误。

## String Initializable

任何实现了 `StringInitializable` 协议的类型都可以作为类型安全的路由参数。默认情况下，下面的类型都实现了：

- String
- Int
- Model

`String` 是最一般的，且始终能匹配成功的。`Int` 类型只有在提供的 string 能够转换成 integer 的时候才会匹配。`Model` 只有提供的字符串作为一个 identifier 能够在数据库中查找到 model 的时候才会匹配。

我们前面使用 user 的例子，可以变得更加加单。

```swift
drop.get("users", User.self) { request, user in
  return "You requested \(user.name)"
}
```

这里提供的 identifier 被自动用来去查找 user。例如，如果 `/users/5` 被请求，`User` 就会去找一个 identifier 为 `5` 的 user。如果找到一个，这个请求将会成功并且回调将会被调用。如果没有找到，将会抛出未找到的错误。

下面展示了，如果 model 没有实现 `StringInitializable` 协议应该怎么处理。

```swift
drop.get("users", Int.self) { request, userId in
  guard let user = try User.find(userId) else {
    throw Abort.notFound
  }

    return "You requested User #\(userId)"
}
```

总而言之，类型安全路由可以从每个路由节省大约6行代码。

### Protocol

使你的类型实现 `StringInitializable` 是很简单的。

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

这个 `init` 可以 `throw` 和返回 `nil`。这个允许你 `throw` 你自己的错误。或者你想要默认的错误和处理，只返回 `nil` 就可以了。

### Limits

Type safe routing is currently limited to three path parts. This is usually remedied by adding route [groups](group.md).
类型安全路由目前仅限于三个路径部分。这个经常添加路由 [groups](group.md) 补救。

```swift
drop.group("v1", "users") { users in
  users.get(User.self, "posts", Post.self) { request, user, post in
    return "Requested \(post.name) for \(user.name)"
  }
}
```

The resulting path for the above example is `/v1/users/:userId/posts/:postId`. If you are clamoring for more type safe routing, please let us know and we can look into increasing the limit of three.
匹配上面的例子的路径是 `/v1/users/:userId/posts/:postId`。如果你强烈要求更多的类型安全路由，请让我们知道，我们会调查决定是否提高只有三个的限制。

## Manual

一般我们使用都会如上面展示的那样，但是你也可以自由的使用传统的路由。这个尤其在复杂场景下有用。


```swift
drop.get("v1", "users", ":userId", "posts", ":postId", "comments", ":commentId") { request in
  let userId = try request.parameters.extract("userId") as Int
  let postId = try request.parameters.extract("postId") as Int
  let commentId = try request.parameters.extract("commentId") as Int

  return "You requested comment #\(commentId) for post #\(postId) for user #\(userId)"
}
```

> `request.parameters` 属性用于提取在 URI _路径_ 中的被编码过的参数（例如 `/v1/users/1` 有参数 `:userId` 是 `"1"`）。在参数作为 _query_ 的一部分传递过来的时候（例如：`/v1/search-user?userId=1`），应该使用 `request.data` （例如 `let userId = request.data["userId"]?.string`）。

请求参数要么作为字典访问，要么使用 `extract` 语法访问。后者使用 throws 代替返回一个 optional 值。

### Groups

手动处理请求参数也可以和 [groups](group.md) 在一起使用。

```swift
let userGroup = drop.grouped("users", ":userId")
userGroup.get("messages") { req in
    let user = try req.parameters.extract("userId") as User
}
```
