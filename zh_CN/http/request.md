---
currentMenu: http-request
---

> Module: `import HTTP`

# Request

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

我们将要与之交互的 `HTTP` 库最常用的部分是 `Request` 类型。这里我们看一下在这个类型上最常用的一些特性。

```swift
public var method: Method
public var uri: URI
public var parameters: Node
public var headers: [HeaderKey: String]
public var body: Body
public var data: Content
```

### Method

与 `Request` 关联的 HTTP `Method`，即：`GET`，`POST`，`PUT`，`PATCH`，`DELETE`。

### URI

与 request 的 `URI` 相关。我们将使用它去访问被发送过来的 `uri` 相关的特性。

例如，有如下的 uri：`http://vapor.codes/example?query=hi#fragments-too`

```swift
let scheme = request.uri.scheme // http
let host = request.uri.host // vapor.codes

let path = request.uri.path // /example
let query = request.uri.query // query=hi
let fragment = request.uri.fragment // fragments-too
```

### 路由参数 （Route Parameters）

与 request 相关的 url 参数。例如：我们有一个注册到 droplet 中的路径是：`hello/:name/age/:age`，我们在我们的请求中访问到它们
的代码类似如下：

```swift
let name = request.parameters["name"] // String?
let age = request.parameters["age"]?.int // Int?
```

或者，要想自动在 `nil` 或者非法变量的时候抛出错误，你也可以使用 `extract`。

```swift
let name = try request.parameters.extract("name") as String
let age = try request.parameters.extract("age") as Int
```

这些 extract 函数能够转换为任何 `NodeInitializable` 类型,也包括你的自定义类型。阅读 [Node](https://github.com/vapor/node) 获取更多信息。

> 注意： Vapor 也天宫类型安全路由，在我们文档的 routing 章节有详细说明。


### Headers

这是与 request 相关的 header。如果您正在准备发出请求，这个能够用来添加你自己的 key。

```swift
let contentType = request.headers["Content-Type"]  
```

或者发送请求：

```swift
let request = Request ...
request.headers["Content-Type"] = "application/json"
request.headers["Authorization"] = ... my auth token
```

#### Extending Headers

我们一般寻求在可能的情况下删除强（stringly）类型代码来改进代码库。我们可以使用泛型扩展添加变量到 header 中。

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

随着这种模式的实现，我们的 `"Custom-Key"` 字符串，只会包含在我们的代码的一个地方。我们现在可以类似下面那样访问它：

```swift
let customKey = request.headers.customKey

// or

let request = ...
request.headers.customKey = "my custom value"
```

### Body

这是与 request 相关的 body，表示普通的 data payload。你能够在 [docs](./body.md) 了解更多与 body 相关的内容。

对于到来的 request，我们经常这样拉取相关的 byte 数据。

```swift
let rawBytes = request.body.bytes
```

## Content

一般当我们发送或收到 request 的时候，我们使用它们作为传输内容的方式。为此，Vapor 提供了一个与请求相关联的方便的 `data` 变量，以一致的方式优先处理 content。

例如：我收到你一个请求： `http://vapor.codes?hello=world`。

```swift
let world = request.data["hello"]?.string
```

如果我收到一个 JSON request，这段代码也能够很好的运行，例如：

```json
{
  "hello": "world"
}
```

仍然能够通过 data 访问到。

```swift
let world = request.data["hello"]?.string
```
> 注意：强制解包应该不要使用。

这个同样适用于 multi-part 请求，甚至通过 middleware 能够扩展到新的类型，例如 XML 或 YAML。

如果你更希望访问的给定类型更加明确，那也没有问题。`data` 变量对于那些想要它的人来说，选择类型是十分方便的。

## JSON

在给定的 request 上直接访问 JSON，可以使用如下代码：

```swift
let json = request.json["hello"]
```

## Query Parameters

这同样适用于 query convenience:

```swift
let query = request.query?["hello"]  // String?
let name = request.query?["name"]?.string // String?
let age = request.query?["age"]?.int // Int?
let rating = request.query?["rating"]?.double // Double?
```

## Key Paths

Key path 适用于大多数可以嵌套键值对象的 Vapor 类型。这里有个例子展示如何访问如下的 json：


```json
{
  "metadata": "some metadata",
  "artists" : {
    "href": "http://someurl.com",
    "items": [
      {
        "name": "Van Gogh",
      },
      {
        "name": "Mozart"
      }
    ]
  }
}
```

我们将要通过如下方式访问 data：

### Metadata

访问最顶层的值

```swift
let type = request.data["metadata"].string // "some metadata"
```

### Items

访问嵌套类型

```swift
let items = request.data["artists", "items"] // [["name": "Van Gogh"], ["name": "Mozart"]]
```

### 混合 Array 和 Object （Mixing Arrays and Objects）

获取第一个 artist

```swift
let first = request.data["artists", "items", 0] // ["name": "Van Gogh"]
```

### Array Item

获取 array 中某个 item 的 key 对应的值

```swift
let firstName = request.data["artists", "items", 0, "name"] // "Van Gogh"
```

### Array Comprehension

我们还可以聪明地映射键的数组，例如，获取所有 artist 的名字，我们能够使用如下代码：

```swift
let names = request.data["artists", "items", "name"] // ["Van Gogh", "Mozart"]
```
