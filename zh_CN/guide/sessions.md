---
currentMenu: guide-sessions
---

# Sessions

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Session 帮助你在请求中保存用户相关的信息。只要客户端支持cookie，session 就很容易创建。

## Middleware

可以通过添加 `SessionMiddleware` 的实例，在你的 `Droplet` 中启动 session。

```swift
import Sessions

let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
```

然后添加到 `Droplet`。

```
let drop = Droplet()
drop.middleware.append(sessions)
```

> 注意： 如果你希望基于配置文件去启用或者禁用中间件，可以查看 [中间件](../guide/middleware.md)。

## Request

在 `SessionMiddleware` 被启用后，你能够通过 `req.sessions()` 方法获取 session 中的数据。

```swift
let data = try req.session().data
```

## Example

让我们创建一个例子，用于记住用户名。

### Store

```swift
drop.post("remember") { req in
    guard let name = req.data["name"]?.string else {
        throw Abort.badRequest
    }

    try req.session().data["name"] = Node.string(name)

    return "Remebered name."
}
```

在 `POST /remember` 请求上，从请求输入汇总获取 `name` 值，并且把它存储到 session 数据中。

### Fetch

在 `GET /remember` 请求中，从 session 中获取 `name` 并返回它。

```swift
drop.get("remember") { req in
    guard let name = try req.session().data["name"]?.string else {
        return throw Abort.custom(status: .badRequest, message: "Please POST the name first.")
    }

    return name
}
```

## Cookie

这个 session 将会使用 `vapor-session` cookie 存储。
