---
currentMenu: auth-protect
---

# Protect

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

一旦 `AuthMiddleware` 被启用，你可以使用 `ProtectMiddleware` 阻止某些 route 被没有授权的用户访问。

## Create

要创建一个 `ProtectMiddleware`，你需要给它一个在授权失败时候抛出的错误。

```swift
let error = Abort.custom(status: .forbidden, message: "Invalid credentials.")
let protect = ProtectMiddleware(error: error)
```

这里我们传递给它一个简单的 403 response。

## Route Group

一旦中间件被创建，你可以添加它到 route group。在 [route groups](../routing/group.md) 可以学习更多关于中间件和路由（middleware and routing）相关的内容。

```
drop.grouped(protect).group("secure") { secure in
    secure.get("about") { req in
        let user = try req.user()
        return user
    }
}
```

访问 `GET /secure/about` 将会返回一个授权的 user，或者用户未授权的时候返回一个错误。
