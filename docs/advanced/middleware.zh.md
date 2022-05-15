# Middleware

Middleware 是 client 和路由处理程序间的一个逻辑链。它允许你在传入请求到达路由处理程序之前对传入请求执行操作，并且在输出响应到达 client 之前对传出响应执行操作。

## Configuration

可以使用 `app.middleware` 在 `configure(_:)` 中全局（针对每条路由）注册 Middleware。

```swift
app.middleware.use(MyMiddleware())
```

你也可以通过路由组的方式给单个路由添加 Middleware。

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
// 该请求通过 MyMiddleware 传递。
}
```

### Order

Middleware 的添加顺序非常重要。进入应用程序的请求将按照在 middleware 添加的顺序依次执行。
离开应用程序的响应将以相反的顺序通过 Middleware 返回。特定的路由 Middleware 始终在应用程序 Middleware 之后运行。

请看以下示例：

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

`GET /hello` 这个请求将按照以下顺序访问 Middleware：

```
Request → A → B → C → Handler → C → B → A → Response
```

## File Middleware

`FileMiddleware` 允许从项目的 Public 文件夹向 client 提供资源。你可以在这里存放 css 或者位图图片等静态文件。

```swif
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

一旦注册 `FileMiddleware`，比如 `Public/images/logo.png` 的文件可以在 Leaf 模板通过 `<img src="/images/logo.png"/>` 方式引用。


## CORS Middleware

跨域资源共享（Cross-origin resource sharing，缩写：CORS），用于让网页的受限资源能够被其他域名的页面访问的一种机制。通过该机制，页面能够自由地使用不同源（英語：cross-origin）的图片、样式、脚本、iframes 以及视频。Vapor 内置的 REST API 需要 CORS 策略，以便将请求安全地返回到 Web 浏览器。

配置示例如下所示：

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
let error = ErrorMiddleware.default(environment: app.environment)
// 清除现有的 middleware。
app.middleware = .init()
app.middleware.use(cors)
app.middleware.use(error)
```

由于抛出的错误会立即返回给客户端，因此必须在 `ErrorMiddleware` 之前注册 `CORSMiddleware`。否则，将返回不带 CORS 标头的 HTTP 错误响应，且浏览器无法读取该错误响应。
