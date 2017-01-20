---
currentMenu: guide-middleware
---

# 中间件 （Middleware）

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

中间件是任何一个现代 web 框架基本的组成部分。它允许你在客户端和服务器之间传输时修改 request 和 response。

You can imagine middleware as a chain of logic connection your server to the client requesting your web app.
你可以把中间件想象成为连接你的服务器到请求你的 web app 的客户端的一系列的逻辑。

## Basic

下面一个例子，创建一个中间件，将会为每个 response 添加 version。这个中间件看起来类似这样：

```swift
final class VersionMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)

        response.headers["Version"] = "API v1.0"

        return response
    }
}
```

然后我们将这个中间件应用于 `Droplet`。

```swift
let drop = Droplet()
drop.middleware.append(VersionMiddleware())
```

你可以认为我们的 `VersionMiddleware` 位于连接客户端到我们 server 的链 （chain）的中间。

![Middleware](https://cloud.githubusercontent.com/assets/1342803/17382676/0b51d6d6-59a0-11e6-9cbb-7585b9ab9803.png)


## 分解 （Breakdown）

让我们一行一行代码的分解中间件。

```swift
let response = try next.respond(to: request)
```

在我们的例子中，由于 `VersionMiddleware` 不关注修改 request，我们直接交给在 chain 中的下一个中间件响应这个请求。这将沿着 chain 到达 `Droplet`，然后返回需要发送给客户端的 response。

```swift
response.headers["Version"] = "API v1.0"
```

然后我们 _修改_ 了 response，使其包含了 Version 头信息。

```swift
return response
```

这个 response 将会被返回，并且向上进入剩下的中间件，并最终返回给客户端。

## Request

中间件也可以修改或者影响 request。

```swift
func respond(to request: Request, chainingTo next: Responder) throws -> Response {
    guard request.cookies["token"] == "secret" else {
        throw Abort.badRequest
    }

    return try next.respond(to: request)
}
```

这个中间件要求 request 有一个名字为 `token` 的cookie，并且等于 `secret`，否则将会抛弃这个请求。

## Errors

中间件最好的地方是用来捕获从程序任何地方抛出的错误。当你让中间件捕获错误，你可以从你的 route 闭包中移除好多重复的逻辑。下面有一个例子：

```swift
enum FooError: Error {
    case fooServiceUnavailable
}
```

这是一个自定义的 error，它可以是你定义的或者是你使用的 API `throws` 的。当这个 error 抛出的时候必须被捕获，否则这个将会作为一个意外的服务器错误返回给用户。最明显的解决方式就是在 route 的闭包里捕获这类错误。

```swift
app.get("foo") { request in
    let foo: Foo
    do {
        foo = try getFooFromService()
    } catch {
        throw Abort.badRequest
    }

    // continue with Foo object
}
```

这个解决方式可以正常工作，但是如果在多个 route 中重复逻辑，这个代码将会被到处重复。幸运的是，这个错误可以在中间件中捕获。

```swift
final class FooErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch FooError.fooServiceUnavailable {
            throw Abort.custom(
                status: .badRequest,
                message: "Sorry, we were unable to query the Foo service."
            )
        }
    }
}
```

我们仅仅需要添加这个中间件到 `Droplet`。

```swift
drop.middleware.append(FooErrorMiddleware())
```

现在我们的 route 闭包看起来更好了，并且我们也不用担心代码重复了。

```swift
app.get("foo") { request in
    let foo = try getFooFromService()

    // continue with Foo object
}
```

有趣的是，如果 `抛弃（Abort）` 它自己是 Vapor 实现的。`AbortMiddleware` 捕获任何 `Abort` 错误，并且返回一个 JSON response。如果你想自定义 `Abort` 错误出现时候的处理方式，你能够移除它并添加你自己的中间件。

## Configuration

添加中间件到 `drop.middleware` 数组是添加中间件最简单的方式，它将在每次应用程序启动时使用。

你也能够使用 [configuration](config.md) 文件来启用或者禁用中间件以进行更多控制。例如，如果你有中间件只会运营在生产环境，这个将会非常有用。

可以像下面一样添加可配置的中间件：

```swift
let drop = Droplet()
drop.addConfigurable(middleware: myMiddleware, name: "my-middleware")
```

然后，在 `Config/droplet.json` 文件，添加 `my-middleware` 到合适的 `middleware` 数组。

```json
{
    ...
    "middleware": {
        "server": [
            ...
            "my-middleware",
            ...
        ],
        "client": [
            ...
        ]
    },
    ...
}
```

如果在加载配置的时候，被添加的中间件的名字出现在了 `server` 数组中，当程序启动的时候，它将会被添加到 server 的中间件中。

如果在加载配置的时候，被添加的中间件的名字出现在了 `client` 数组中，当程序启动的时候，它将会被添加到 client 的中间件中。

一个中间件可以同时出现在 client 和 server 中，并且可以被添加多次。添加的顺序是有影响的。

## Extensions (Advanced)

Middleware pairs great with request/response extensions and storage.
中间件可以和 request/response、存储搭配使用

```swift
final class PokemonMiddleware: Middleware {
    let drop: Droplet
    init(drop: Droplet) {
        self.drop = drop
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)

        if let pokemon = response.pokemon {
            if request.accept.prefers("html") {
                response.view = try drop.view("pokemon.mustache", context: pokemon)
            } else {
                response.json = try pokemon.makeJSON()
            }
        }

        return response
    }
}
```

为 `Response` 添加扩展。

```swift
extension Response {
    var pokemon: Pokemon? {
        get { return storage["pokemon"] as? Pokemon }
        set { storage["pokemon"] = newValue }
    }
}
```

在这个例子中，我们为 response 添加了一个新的属性，能够持有一个 Pokémon 对象。如果中间件发现一个带有 Pokémon 对象的 response，它将动态的检查客户端是否想要 HTML。如果客户端是类似 Safari 的浏览器，并且想要 HTML，它将返回一个 Mustache 视图。如果客户端不想要 HTML，它将返回 JSON。

现在你的闭包可以像下面一样了：

```swift
import HTTP

drop.get("pokemon", Pokemon.self) { request, pokemon in
    let response = Response()
    response.pokemon = pokemon
    return response
}
```

或者，如果你想更加深入，你可以使 `Pokemon` 实现 `ResponseRepresentable` 协议。

```swift
import HTTP

extension Pokemon: ResponseRepresentable {
    func makeResponse() throws -> Response {
        let response = Response()
        response.pokemon = self
        return response
    }
}
```

现在你的闭包会更加的简单，并且不需要 `import HTTP` 了。

```swift
drop.get("pokemon", Pokemon.self) { request, pokemon in
    return pokemon
}
```

中间件非常的强大。结合扩展，它允许您添加感觉框架本身的功能。

对于那些好奇的人，这就是 Vapor 如果在内部管理 JSON 的。无论何时你在闭包中返回 JSON，它将设置在 `Response` 设置 `json: JSON?` 属性。`JSONMiddleware` 中间件将会获得这个属性，并且序列化该 JSON 到 response body 中。
