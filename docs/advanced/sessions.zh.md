# 会话

会话允许你在多个请求之间持久化用户的数据。会话通过在初始化新会话时创建并返回一个唯一的 cookie 以及 HTTP 响应来工作。浏览器会自动检测到此 cookie， 并将其包含在未来的请求中。这允许 Vapor 在你的请求处理中自动恢复特定用户的会话。

会话非常适合内置在 Vapor 中的前端应用程序，这些应用程序直接向浏览器提供 HTML。对于 API，在请求之间保留用户数据，我们建议使用无状态、[基于令牌的身份验证](../security/authentication.md)方式。

## 配置

要在路由中使用会话，请求必须通过 `SessionsMiddleware` 中间件。 最简单的实现方式是全局添加此中间件。

```swift
app.middleware.use(app.sessions.middleware)
```

如果只有一部分路由使用会话，可以添加 `SessionsMiddleware` 中间件到路由组。

```swift
let sessions = app.grouped(app.sessions.middleware)
```

使用 `app.sessions.configuration` 配置会话生成的 HTTP cookie。你可以更改 cookie 名称并声明一个自定义函数来生成 cookie 值。

```swift
// 更改 cookie 名称为 ”foo“。
app.sessions.configuration.cookieName = "foo"

// 配置 cookie 值创建。
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}
```

默认情况下，Vapor 将 `vapor_session` 作为 cookie 名称。

## 驱动

会话驱动程序负责按标识符存储和检索会话数据。你可以通过遵循 `SessionDriver` 协议来创建自定义驱动程序。

!!! warning "警告"
    应用程序中的会话驱动程序应在添加 `app.sessions.middleware` 前进行配置。

### 内存中

默认情况下，Vapor 使用内存中的会话。内存会话不需要配置，并且不会在应用程序启动之间持续存在，这使得它们非常适合测试。要手动启用内存会话，请使用 `.memory` 进行配置：

```swift
app.sessions.use(.memory)
```

对于生产用例，请查看其他会话驱动程序，在你的应用程序的多个实例之间它们利用数据库持久化和共享会话。

### Fluent

Fluent 支持将会话数据存储在应用程序的数据库中。本节假设你[已配置 Fluent](../fluent/overview.zh.md) 并且可以连接到数据库。第一步是启用 Fluent 会话驱动程序。

```swift
import Fluent

app.sessions.use(.fluent)
```

这将配置会话以使用应用程序的默认数据库。要指定特定数据库，请传递数据库的标识符。

```swift
app.sessions.use(.fluent(.sqlite))
```

最后，将 `SessionRecord` 迁移添加到数据库的迁移中。这将为在 `_fluent_sessions` 模式中存储会话数据准备好数据库。

```swift
app.migrations.add(SessionRecord.migration)
```

确保在添加新迁移后运行应用程序的迁移。会话现在将存储在你的应用的数据库中，允许它们在重新启动之间持久存在，并在应用程序的多个实例之间共享。

### Redis

Redis 支持在你配置的 Redis 实例中存储会话数据。本部分假设你[已配置 Redis](../redis/overview.zh.md)，并且可以向 Redis 实例发送命令。

要使用 Redis 处理会话，请在配置应用程序时选择它：

```swift
import Redis

app.sessions.use(.redis)
```

这将配置会话以使用具有默认行为的 Redis 会话驱动程序。

!!! seealso "也可以看看"
    了解有关 Redis 和 Sessions 的更多信息，请参阅[Redis → Sessions](../redis/sessions.zh.md)。

## 会话数据

配置好会话之后，就可以在请求之间持久化数据了。当数据添加到 `req.session` 时，新的会话会自动初始化。下面的示例展示了路由处理中接受一个动态路由参数，并将值添加到 `req.session.data` 中。

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

使用以下请求来初始化一个名为 Vapor 的会话。

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

你应该会收到类似于以下内容的响应：

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

注意，在向 `req.session` 中添加数据后，`set-cookie` 被自动添加到响应头中。在后续请求中包含此 cookie 将允许访问会话数据。

添加以下路由处理以从会话中访问名称值。

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

使用以下请求访问此路由，同时确保传递上一个响应中的 cookie 值。

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

你应该看到响应中返回的名称 Vapor。你可以根据需要在会话中添加或删除数据。在返回 HTTP 响应之前，会话数据将自动与会话驱动程序同步。

要结束会话，请使用 `req.session.destroy` 方法。 这将从会话驱动程序中删除数据并使会话 cookie 无效。

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
