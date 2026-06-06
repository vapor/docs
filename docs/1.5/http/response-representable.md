---
currentMenu: http-response-representable
---

> Module: `import HTTP`

# ResponseRepresentable

Traditionally HTTP servers take a `Request` and return a `Response`. Vapor is no different, but we can take advantage of Swift's powerful protocols to be a bit more flexible to the user facing API.

Let's start with the definition of `ResponseRepresentable`

```swift
public protocol ResponseRepresentable {
    func makeResponse() throws -> Response
}
```

By conforming to this protocol, we can more flexibly return things that conform instead of creating the response manually each time. Vapor provides some of these by default. Including (but not limited to):

### String

Because string conforms to `ResponseRepresentable`, we can return it directly in a Vapor route handler.

```swift
drop.get("hello") { request in
  return "Hello, World!"
}
```

### JSON

`JSON` can be returned directly instead of recreating a response each time.

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

Of course, we can also return Responses for anything not covered:

```swift
drop.get("hello") { request in
  return Response(status: .ok, headers: ["Content-Type": "text/plain"], body: "Hello, World!")
}
```

## Conforming

All we need to do to return our own objects is conform them to `ResponseRepresentable`. Let's look at an example type, a simple blog post model:

```swift
import Foundation

struct BlogPost {
  let id: String
  let content: String
  let createdAt: NSDate
}
```

And now, let's conform it to response representable.

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

> Don't forget to import HTTP.

Now that we've modeled our BlogPost, we can return it directly in route handlers.

```swift
drop.post("post") { req in
  guard let content = request.data["content"] else { throw Error.missingContent }
  let post = Post(content: content)
  try post.save(to: database)
  return post
}
```
