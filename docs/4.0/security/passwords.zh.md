# 密码

Vapor 包含一个密码哈希 API，可帮助你安全地存储和验证密码。此 API 可根据环境进行配置，并支持异步哈希。

## 配置

使用 `app.passwords` 配置应用的密码哈希器

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

要使用 Vapor 的 [Bcrypt API](crypto.zh.md#bcrypt) 进行密码哈希，请指定 `.bcrypt`。这也是默认设置。

```swift
app.passwords.use(.bcrypt)
```

除非另有说明，否则 Bcrypt 将使用 cost 为12的默认值。你可以通过传递 `cost` 参数来配置它。

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### 纯文本

Vapor 包含一个不安全的密码哈希器，它以明文形式存储和验证密码。这不应该在生产环境中使用，但对测试很有用。

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashing

使用 `Request` 对象上的 `password` 辅助函数对密码进行哈希。

```swift
let digest = try req.password.hash("vapor")
```

可以使用 `verify` 方法针对明文密码验证密码摘要。

```swift
let bool = try req.password.verify("vapor", created: digest)
```

同样的 API 也可以在 `Application` 中使用。

```swift
let digest = try app.password.hash("vapor")
```

### 异步 

密码哈希算法被设计成速度慢且耗费 CPU 资源。在对密码进行哈希时，你可能希望避免阻塞事件循环。Vapor 提供了一个异步密码哈希 API，它将哈希分派给后台线程池。要使用异步 API，请使用密码哈希器上的 `async` 属性。

```swift
req.password.async.hash("vapor").map { digest in
    // Handle digest.
}

// or

let digest = try await req.password.async.hash("vapor")
```

验证摘要的工作原理类似：

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Handle result.
}

// or

let result = try await req.password.async.verify("vapor", created: digest)
```

在后台线程上计算哈希值可以释放应用程序的事件循环来处理更多的传入请求。


