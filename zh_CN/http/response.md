---
currentMenu: http-response
---

> Module: `import HTTP`

# Response

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

在构建 endpoint 时，我们通常会返回请求的响应。如果我们发出请求，我们会收到他们。

```swift
public let status: Status
public var headers: [HeaderKey: String]
public var body: Body
public var data: Content
```

#### Status

http status 是与事件相关的，例如：`.ok` == 200 ok。

#### Headers

这些是与请求相关联的 header。如果你准备返回 response，这个可以用于添加你自己的 key。

```swift
let contentType = response.headers["Content-Type"]  
```

或者返回 response：

```swift
let response = response ...
response.headers["Content-Type"] = "application/json"
response.headers["Authorization"] = ... my auth token
```

##### Extending Headers

我通常通过在代码中尽可能的移除硬编码类型代码，提高代码质量。我们能够通过泛型向 header 中添加变量。

```swift
extension KeyAccessible where Key == HeaderKey, Value == String {
    var customKey: String? {
      get {
        return self["Custom-Key"]
      }
      set {
        self["Custom-Key"] = newValue
      }
    }
}
```

使用这种模式实现，我们的字符串 `"Custom-Key"` 只会包含在我们代码的一个地方。我们现在可以像下面那样访问它。

```swift
let customKey = response.headers.customKey

// or

let request = ...
response.headers.customKey = "my custom value"
```

#### Body

这是与 response 相关的 body，表示普通的 data payload。你能够在 [docs](./body.md) 了解更多与 body 相关的内容。

对于 response 来说，body 通常在初始化的时候设置。response 有两种主要的类型。

##### BodyRepresentable

能够被转换成 byte 的东西，例如：

```swift
let response = Response(status: .ok, body: "some string")
```

上面的例子中，`String` 将会被自动转换为 body。你自定义的类型也可以这样做。

##### Bytes Directly

如果我们已经有 byte 数组，我们可以把它传到 body 里，像下面这样：

```swift
let response = Response(status: .ok, body: .data(myArrayOfBytes))
```

##### Chunked

要分块发送 `HTTP.Response`，我们可以传递一个闭包，我们将使用它来一部分一部分地发送我们的 response body 。

```swift
let response = Response(status: .ok) { chunker in
  for name in ["joe", "pam", "cheryl"] {
      sleep(1)
      try chunker.send(name)
  }

  try chunker.close()
}
```

> 保证你的 chunker 在离开代码范围之前，调用 `close()` 方法。

## Content

我们可以像我们在 [request](./request.md) 中做的那样访问其他内容。这个最长应用在发送请求上。

```swift
let pokemonResponse = try drop.client.get("http://pokeapi.co/api/v2/pokemon/")
let names = pokemonResponse.data["results", "name"]?.array
```

## JSON

To access JSON directly on a given response, use the following:

```swift
let json = request.response["hello"]
```

## Key Paths

阅读更多关于 KeyPaths 内容，请访问 [这里](./request.md#key-paths)。
