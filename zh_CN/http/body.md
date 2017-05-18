---
currentMenu: http-body
---

> Module: `import HTTP`

# Body

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`HTTP.Body` 表示一个 `HTTP.Message` 的有效内容，它用于传递底层数据。在实际中例如 `JSON`、`HTML` 文本，或者图片字节。让我看看它的实现。

```swift
public enum Body {
    case data(Bytes)
    case chunked((ChunkStream) throws -> Void)
}
```

## Data Case

`data` case 是一个 `HTTP.Message` 中 `Body` 的最常见用法。它就是一个 byte 数组。序列化协议或者这些 byte 相关的类型，通常使用 `Content-Type` 定义。让我们看一下例子。

### Application/JSON

如果我们的 `Content-Type` 头中包含 `application/json`，那么底层字节表示序列化的 JSON。

```swift
if let contentType = req.headers["Content-Type"], contentType.contains("application/json"), let bytes = req.body.bytes {
  let json = try JSON(bytes: bytes)
  print("Got JSON: \(json)")
}
```

### Image/PNG

如果我们的 `Content-Type` 头中包含 `image/png`，那么底层字节表示编码过的 png。

```swift
if let contentType = req.headers["Content-Type"], contentType.contains("image/png"), let bytes = req.body.bytes {
  try database.save(image: bytes)
}
```

## Chunked Case

The `chunked` case only applies to outgoing `HTTP.Message`s in Vapor. It is traditionally a responder's role to collect an entire chunked encoding before passing it on. We can use this to send a body asynchronously.    
`chunked` case 只适用于在 Vapor 中传出的 `HTTP.Message`.它是一个传统的 responser 的角色，用于在发送之前收集整个已经编码的 Chunked。

```swift
let body: Body = Body.chunked(sender)
return Response(status: .ok, body: body)
```

我们可以手动实现它，或者使用 Vapor 为 chunked body 内建的便利构造器实现。

```swift
return Response(status: .ok) { chunker in
  for name in ["joe", "pam", "cheryl"] {
      sleep(1)
      try chunker.send(name)
  }

  try chunker.close()
}
```

> 确保在 chunker 离开这个范围之前调用 `close()`。

## BodyRepresentable

除了在 Vapor 中常见的具体的 `Body` 类型，我们对于 `BodyRepresentable` 也有广泛支持。这意味着我们通常转换为 `Body` 类型的对象可以互换使用。例如：

```swift
return Response(body: "Hello, World!")
```

上面的例子中，字符串被转换为 byte，然后添加到 body 中。

> 在实际中，最好使用 `return "Hello, World!"`。Vapor 能够自动设置 `Content-Type` 为合适的值。

让我们看看它是如何实现的：

```swift
public protocol BodyRepresentable {
    func makeBody() -> Body
}
```

### Custom

在适当的情况下，我们也可以使我们自己的类型实现 `BodyRepresentable`。我们假装我们有一个自定义的类型 `.vpr`。让我们实现我们自己 `VPR` 文件类型 model：

```swift
extension VPRFile: HTTP.BodyRepresentable {
  func makeBody() -> Body {
    // collect bytes
    return .data(bytes)
  }
}
```

> You may have noticed above, that the protocol throws, but our implementation does not. This is completely valid in Swift and will allow you to not throw if you're ever calling the function manually.   
> 你可能已经注意到了，`BodyRepresentable` 协议有 throws，但是我们的实现中没有。这在 Swift 中是合法的，如果你已经手动调用了这个函数，可以允许你不 throw。   
> 译者注：说实话是没有看懂，看代码也没懂。

现在我们可以直接在我们的 `Responses` 中包含我们的 `VPR` 文件。

```swift
drop.get("files", ":file-name") { request in
  let filename = try request.parameters.extract("file-name") as String
  let file = VPRFileManager.fetch(filename)
  return Response(status: .ok, headers: ["Content-Type": "file/vpr"], body: file)
}
```

实际中，如果我们经常重复上面代码，我们可以直接使 `VPRFile` 实现 `ResponseRepresentable` 协议。

```swift
extension VPRFile: HTTP.ResponseRepresentable {
  func makeResponse() -> Response {
    return Response(
      status: .ok,
      headers: ["Content-Type": "file/vpr"],
      body: file
    )
  }
}
```

上面的例子可以改成这样：

```swift
drop.get("files", ":file-name") { request in
  let filename = try request.parameters.extract("file-name") as String
  return VPRFileManager.fetch(filename)
}
```

我们也可以使用类型安全路由使这个更加的简洁：

```swift
drop.get("files", String.self) { request, filename in
  return VPRFileManager.fetch(filename)
}
```
