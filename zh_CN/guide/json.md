---
currentMenu: guide-json
---

# JSON

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

JSON是Vapor的一个组成部分。它使 Vapor 的 [Config](config.md) 更加强大，并且它也很容易被使用在 request 和 respose 中。

## Request

在请求的 form-urlencoded 数据 和 query 数据中的 JSON 可以自动的在 `request.data` 获取。这个允许你只关注创建一个强大的 API，不用担心什么数据类型将会被发送过来。

```swift
drop.get("hello") { request in
    guard let name = request.data["name"]?.string else {
        throw Abort.badRequest
    }
    return "Hello, \(name)!"
}
```

This will return a greeting for any HTTP method or content type that the `name` is sent as, including JSON.

### JSON Only

你可以使用 `request.json` 属性，获得明确的 JSON。

```swift
drop.post("json") { request in
    guard let name = request.json?["name"]?.string else {
        throw Abort.badRequest
    }

    return "Hello, \(name)!"
}
```
上面的片段只有在请求发送的数据是 JSON 的情况下才可以正常工作。

## Response

如果想要返回 JSON，只需要使用 `JSON(node: )` 包裹你的数据结构就可以了。

```swift
drop.get("version") { request in
    return try JSON(node: [
    	"version": "1.0"
    ])
}
```

## Middleware

`JSONMiddleware` 默认已经包含在了 `Droplet` 中间件里面了。如果你不想 JSON 被解析，可以移除它。
