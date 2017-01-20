---
currentMenu: http-response-representable
---

> Module: `import HTTP`

# ResponseRepresentable

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

传统的 HTTP Server 接收一个 `Request` 然后返回 `Response`，Vapor 也没有什么不同，但是我们可以利用 Swift 强大的 protocol，使用户见到的 api 更加的灵活。

让我们从定义 `ResponseRepresentable` 开始。

```swift
public protocol ResponseRepresentable {
    func makeResponse() throws -> Response
}
```

通过实现该协议，我们能够更加灵活的返回数据，使用实现协议代替了每次手动创建 response。 Vapor 默认提供一些类似这样的功能，包括（但不限于）：

### String

因为字符串实现了 `ResponseRepresentable` 协议，我们能够在 Vapor 路由的 hanlder 中直接放回它。

```swift
drop.get("hello") { request in
  return "Hello, World!"
}
```

### JSON

`JSON` 也可以直接被返回，而不用每次都创建一个 response。

```swift
drop.get("hello") { request in
  return try JSON(node: [
      "hello": "world",
      "some-numbers": [
        1,
        2,
        3
      ]
    ]
  )
}
```

### Response

当然，我们可以为没有涵盖的任何东西返回一个 Response。

```swift
drop.get("hello") { request in
  return Response(status: .ok, headers: ["Content-Type": "text/plain"], body: "Hello, World!")
}
```

## Conforming

我们需要返回的所有的我们的自己的对象，它们都需要实现 `ResponseRepresentable` 协议。让我们看一个例子，一个简单的 blog post model：

```swift
import Foundation

struct BlogPost {
  let id: String
  let content: String
  let createdAt: NSDate
}
```

现在，让它实现 `ResponseRepresentable` 协议。

```swift
import HTTP
import Foundation

extension BlogPost: ResponseRepresentable {
  func makeResponse() throws -> Response {
    let json = try JSON(node:
      [
        "id": id,
        "content": content,
        "created-at": createdAt.timeIntervalSince1970
      ]
    )
    return try json.makeResponse()
  }
}
```

> 不要忘了 import HTTP。

现在我们已经 model 化了我们的 BlogPost，我可以直接再 route handler 中返回了。

```swift
drop.post("post") { req in
  guard let content = request.data["content"] else { throw Error.missingContent }
  let post = Post(content: content)
  try post.save(to: database)
  return post
}
```
