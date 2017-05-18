---
currentMenu: routing-basic
---

# 基础路由 （Basic Routing）

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

路由是Web框架最重要的部分之一。路由决定哪个 request 获得哪个 response。

Vapor 的路由有很多的功能，包含 route builders, groups, 和 collections。在本章节，我们将看一下最路由的基础。

## 注册 （Register）

大多数基础路由都包含请求方法、路径、闭包。

```swift
drop.get("welcome") { request in
    return "Hello"
}
```

`get`, `post`, `put`, `patch`, `delete`, and `options` 等标准的 HTTP 请求方法都是可用的。

```swift
drop.post("form") { request in
    return "Submitted with a POST request"
}
```

你也可以使用 `any`  匹配所有的请求方法。

## Nesting

通过添加逗号，我们能够获得嵌套路径（在你的 URL 中添加 `/`）。

```swift
drop.get("foo", "bar", "baz") { request in
    return "You requested /foo/bar/baz"
}
```

你也可以使用 `/`，但是逗号更容易输入并且能够和类型安全的路由 [参数](parameters.md) 运行的更好。

## Alternate

另外一个语法，接收一个 `Method` 作为一个参数也是可用的。

```swift
drop.add(.trace, "welcome") { request in
    return "Hello"
}
```

This may be useful if you want to register routes dynamically or use a less common method.
如果你想动态注册路由或者使用不常用的方法，这个是很有用的。
> 译者注： less common method 表示没看懂。

## Request

每个路由闭包中会传入一个 [Request](../http/request.md) 实例。它包含调用你的闭包的 request 的所有的数据。

## Response Representable

一个路由可用有三种返回方式：

- `Response`
- `ResponseRepresentable`
- `throw`

### Response

自定义的 [Response](../http/response.md) 可用被返回。

```swift
drop.get("vapor") { request in
    return Response(redirect: "http://vapor.codes")
}
```

这个对于创建特殊的 response 十分有用，比如重定向。同样当你想添加 cookie 或者 其他东西到 response 中，这个是很有用的。

### 自描述的 Response （Response Representable）

就像你在前面的例子中看到的一样， `String` 可用被路由的闭包返回。这是因为它实现了 [ResponseRepresentable](../http/response-representable.md) 协议。

在 Vapor 中许多类型默认实现了这个协议：
- String
- Int
- JSON
- Model

```swift
drop.get("json") { request in
    return try JSON(node: [
        "number": 123,
        "text": "unicorns",
        "bool": false
    ])
}
```

> 如果你很好奇 `node:` 是什么，可用阅读 [Node](https://github.com/vapor/node)。

### Throwing

如果你不能返回 response，你能够 `throw` 任何一个实现了 `Error` 的对象。Vapor 带有默认的错误枚举 `Abort`。

```swift
drop.get("404") { request in
    throw Abort.notFound
}
```

使用 `Abort` 的时候，你能够定义这些错误的信息。

```swift
drop.get("error") { request in
    throw Abort.custom(status: .badRequest, message: "Sorry 😱")
}
```

默认情况下，这些错误会被 `AbortMiddleware` 捕获到，并且会被转化成一个类似如下的 JSON。

```json
{
    error: true,
    message: "<the message>"
}
```

如果你想覆盖这种行为，从 `Droplet` 移动 `AbortMiddleware` 并添加你自己的中间件。

## Fallback

Fallback routes 允许您匹配多层嵌套斜杠的路径。

```swift
app.get("anything", "*") { request in
    return "Matches anything after /anything"
}
```

例如，上面的路由将匹配下面所有的路径而且还会更多。

- /anything
- /anything/foo
- /anything/foo/bar
- /anything/foo/bar/baz
- ...
