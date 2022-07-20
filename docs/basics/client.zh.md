# Client

Vapor的 `Client` API 允许您使用 HTTP 调用外部资源，它基于 [async-http-client](https://github.com/swift-server/async-http-client) 构建，并集成了 [Content](content.md) API。


## 概述

你可以通过 `Application` 或通过 `Request` 在路由处理回调中访问默认 `Client`。

```swift
app.client // Client

app.get("test") { req in
    req.client // Client
}
```


`Application` 的 `client` 对于在配置期间发起 HTTP 请求非常有用，如果要在路由处理程序中发起 HTTP 请求，请使用 `req.client`。


### 方法

如果你要发起一个 GET 请求，请将所需的 URL 地址传给 `client` 的 `get` 方法，如下所示：

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

HTTP 的常用方法(例如 `get`, `post`, `delete`)都有便捷的调用方式，`client` 的响应会以一个 future 的形式返回，它包含了 HTTP 返回的状态、头部信息和内容。


### Content

Vapor 的 [Content](content.md) API 可用于处理客户请求和响应中的数据，如果要在请求体中添加参数或编码，请在 `beforeSend` 闭包中进行。

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
	// Encode query string to the request URL.
	try req.query.encode(["q": "test"])

	// Encode JSON to the request body.
    try req.content.encode(["hello": "world"])
    
    // Add auth header to the request
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Handle the response.
```

你可以用 `Content` 对 response body 解码采用熟悉的方式：
```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

如果要解码响应的数据，请在 `flatMapThrowing` 回调中处理。

```swift
req.client.get("https://httpbin.org/json").flatMapThrowing { res in
	try res.content.decode(MyJSONResponse.self)
}.map { json in
	// 处理返回的JSON信息
}
```

## 配置

你可以通过 `application` 来配置 HTTP `client` 的基础参数。

```swift
// 禁止自动跳转
app.http.client.configuration.redirectConfiguration = .disallow
```

请注意，你必须在首次使用默认的 `client` 之前对其进行配置。

