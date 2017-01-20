---
currentMenu: http-responder
---

> Module: `import HTTP`

# Responder

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`Responder` 是一个简单的 protocol，用于定义能够能够接收 `Request` 和返回 `Response` 的行为的对象。最值得注意的是在Vapor中，它是连接`Droplet`和`Server`的核心 api 切入点（endpoint）。让我们看看它的定义：

```swift
public protocol Responder {
    func respond(to request: Request) throws -> Response
}
```

> The responder protocol is most notably related to Droplet and it's relationship with a server. Average users will not likely interact with it much.
responder protocol 最明显的是与 Droplet 相关及它与 server 的关系。大部分用户不会直接与它进行交互。

## Simple

当然，Vapor 针对这个提供了了一些便利方法，在实践中，我们经常这样调用：

```swift
try drop.run()
```

## Manual

正如我们刚才提到的，Vapor 的 `Droplet` 自己实现了 `Responder`，连接它到 `Server`。这意味着如果你想手动设置 droplet，我们能按照如下方式：

```swift
let server = try Server<TCPServerStream, Parser<Request>, Serializer<Response>>(port: port)
try server.start(responder: droplet)  { error in
    print("Got error: \(error)")
}
```

## Advanced

我们能够让我们的的对象实现 `Responder` 协议，然后把它传给 `Servers`。让我们看一个例子：

```swift
final class Responder: HTTP.Responder {
    func respond(to request: Request) throws -> Response {
        let body = "Hello World".makeBody()
        return Response(body: body)
    }
}
```

这个例子中，针对每个 request 都会返回 `"Hello World"`，它最常见的是与某种类型的 router 连接 （linked）。

```swift
final class Responder: HTTP.Responder {
    let router: Router = ...

    func respond(to request: Request) throws -> Response {
        return try router.route(request)
    }
}
```

然后我们传递这个 responser 给 server，让它运行起来。

```swift
let server = try Server<TCPServerStream, Parser<Request>, Serializer<Response>>(port: port)

print("visit http://localhost:\(port)/")
try server.start(responder: Responder()) { error in
    print("Got error: \(error)")
}
```

This can be used as a jumping off point for applications looking to implement features manually.
这可以用作希望手动实现应用程序功能的跳转点。

## Client

尽管 `HTTP.Client` 本身也是一个 `Responder`，但是他自己不处理 `Request`，它将 `Request` 传递到底层的 uri。
