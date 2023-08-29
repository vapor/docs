# Request

[`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) 对象被传递到每一个[路由处理程序](../basics/routing.md)中.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

它是进入 Vapor 的主要窗口。包含了用于 [请求体](../basics/content.md)，[查询参数](../basics/content.md#query)，[日志记录器](../basics/logging.md)，[HTTP 客户端](../basics/client.md)，[认证器](../security/authentication.md), 等的 API。 通过请求访问这些功能可以将计算保持在正确的事件循环中，并允许在测试中进行模拟。你甚至可以通过扩展将自己的[服务](../advanced/services.md)添加到 `Request` 中。

完整的 `Request` API 文档可以在[这里](https://api.vapor.codes/vapor/documentation/vapor/request)找到。

## Application

`Request.application` 属性持有对 [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) 的引用。 这个对象包含了应用程序的所有配置和核心功能。大部分配置应该只在 `configure.swift` 中设置，在应用程序完全启动之前进行，许多较低级别的 API 在大多数应用程序中都不会被使用。其中最有用的属性之一 `Application.eventLoopGroup`，它可以通过 `any()` 方法用于需要新的 `EventLoop` 的进程中获取。它还包含了 [`Environment`](../basics/environment.md)。

## Body

如果你想以 `ByteBuffer` 的形式直接访问请求体，可以使用 `Request.body.data`。这可以用于从请求体流式传输数据到文件（尽管在这种情况下应该使用请求的 [fileio](../advanced/files.m) 属性），或者传输到另一个 HTTP 客户端。

## Cookies

虽然最常见的 cookie 应用是通过内置的[会话](../advanced/sessions.md#configuration)进行的，但你也可以通过 `Request.cookies` 直接访问 cookie。

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

通过 `Request.headers` 访问一个 `HTTPHeaders` 对象，其中包含了与请求一起发送的所有标头。例如，可以使用它来访问 `Content-Type` 标头。

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

进一步了解 `HTTPHeaders` 的文档，请参阅[此处](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders)。Vapor 还为 `HTTPHeaders` 添加了几个扩展，以便更轻松地处理最常用的标头；你可以在[此处](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)找到扩展列表。

## IP Address

代表客户端的 `SocketAddress` 可以通过 `Request.remoteAddress` 访问，这可能对于日志记录或使用字符串表示的 `Request.remoteAddress.ipAddress` 进行速率限制很有用。如果应用程序在反向代理后面，则可能无法准确表示客户端的 IP 地址。

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

了解更多 `SocketAddress` 文档，请参阅[此处](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress)。




