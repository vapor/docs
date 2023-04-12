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
离开应用程序的响应将以相反的顺序通过 Middleware 返回。特定的路由 Middleware 始终在应用程序 Middleware 之后运行。请看以下示例：

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

中间件也可以 _预先_ 添加，当你想在 vapor 自动添加的默认中间件 _之前_ 添加一个中间件时，这很有用:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## 创建一个中间件

Vapor 附带了一些有用的中间件，但你可以根据需要创建自己的中间件。例如，你可以创建一个中间件来阻止任何非管理员用户访问一组路由。

> 我们建议在 `Sources/App` 目录中创建一个 `Middleware` 文件夹，来组织你的代码。
 
中间件类型遵循 `Middleware` 协议或 `AsyncMiddleware` 协议。它们被插入到响应链中，可以在请求到达路由处理之前访问和操作请求，也可以在返回响应之前访问和操作响应。

使用上面提到的例子，创建一个中间件来阻止非管理员用户的访问:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

或者使用 `async`/`await` 你可以这样写：

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

如果你想修改响应，例如添加一个自定义 header，你也可以为此使用一个中间件。中间件可以等待，直到从响应链接收到响应，然后对响应进行操作：

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

或者使用 `async`/`await` 你可以这么写：

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

`FileMiddleware` 允许从项目的 Public 文件夹向 client 提供资源。你可以在这里存放 css 或者位图图片等静态文件。

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

一旦注册 `FileMiddleware`，比如 `Public/images/logo.png` 的文件可以在 Leaf 模板通过 `<img src="/images/logo.png"/>` 方式引用。

如果你的服务器包含在一个 Xcode 项目中，比如一个 iOS 应用，可以使用以下代码代替：

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

同时，请确保在 Xcode 中使用文件夹引用（Folder References）而不是 Xcode 中的组（Groups）来保持资源文件夹结构在构建应用程序后不变。


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
