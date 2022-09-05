# Async

## Async Await

Swift 5.5 在语言层面上以 `async`/`await` 的形式引进了并发性。它提供了优秀的方式去处理异步在 Swift 以及 Vapor 应用中。

Vapor 是在 [SwiftNIO](https://github.com/apple/swift-nio.git) 的基础上构建的, SwiftNIO 为低层面的异步编程提供了基本类型。在引入 `async`/`await` 之前，这些类型曾经是（现在依然是）贯穿了整个 Vapor。现在大部分代码可以用 `async`/`await` 编写来代替 `EventLoopFuture`。这将简化你的代码，使其更容易推理。

大部分 Vapor 的 API 同时提供 `EventLoopFuture` 和 `async`/`await` 两个版本供你选择。通常，你应该只选择一种编程方式来处理单个路由，而不应该混用。对于需要显示控制事件循环的应用程序，或者非常高性能的应用程序，应该继续使用 `EventLoopFuture` 直到实现自定义执行程序。对于其他应用，你应该使用 `async`/`await` 因为它的好处、可读性和可维护性远远超过了任何小的性能损失。

### 迁移到 async/await

迁移到 async/await 需要几个步骤。首先，如果你使用 macOS，你必须使用 macOS 12 Monterey 或者更高版本以及 Xcode13.1 或者更高版本。对于其他平台你需要运行 Swift5.5 或者更高版本，然后请确认你已经更新了所有依赖项。

在你的 Package.swift 文件中, 在第一行把 swift-tools-version 设置为 5.5：

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

接下来，设置平台版本为 macOS 12：

```swift
    platforms: [
       .macOS(.v12)
    ],
```

最后更新 `Run` 目标让它变成一个可运行的目标：

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

注意：如果你部署在 Linux 环境请确保你更新到了最新的 Swift 版本。比如在 Heroku 或者在你的 Dockerfile。举个例子你的 Dockerfile 应该变为：

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

现在你可以适配现有代码。通常返回 `EventLoopFuture` 的方法现在变为返回 `async`。比如：

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

现在变为：

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### 使用新旧 API

如果你遇到还未支持 `async`/`await` 的 API，你可以调用 `.get()` 方法来返回一个 `EventLoopFuture` 来转换它。

比如

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // 使用 futureResult
}
```

可以变为

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

如果你需要反过来，你可以转换

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

变为

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`

你可能已经注意到在 Vapor 中一些 API 期望或返回一个 `EventLoopFuture` 的泛型。如果这是你第一次听说 future 对象，一开始可能看起来有点令人困惑。但是别担心本指南会教你怎么利用这些强大的 API。

Promises 和 Futures 是相关但是截然不同的类型。Promises 用于 _创建_ futures。大多数时候，你将使用 Vapor 的 API 返回的 future 对象，无需担心创建 Promise。

|类型|描述|是否可修改|
|-|-|-|
|`EventLoopFuture`|引用一个可能尚不可用的值|只读|
|`EventLoopPromise`|一个可以异步提供值的 promise|读/写|


Futures 是基于回调的异步 API 的替代方案。Futures 可以以简单的闭包所不能的方式进行链接和转换。

## 转换

就像 Swift 中的可选值和数组一样，futures 可以被映射和平映射。这些是你在 futures 上执行的最常见操作。

|方法|参数|描述|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Maps a future value to a different value.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Maps a future value to a different value or an error.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Maps a future value to different _future_ value.|
|[`transform`](#transform)|`U`|Maps a future to an already available value.|

如果你看一下 `map` 和 `flatMap` 在 `Optional<T>` 和 `Array<T>` 中的方法签名。你会看到他们和在 `EventLoopFuture<T>` 中的方法非常相似。

### map

`map` 方法允许你把一个 future 值转换成另外一个值。 因为这个 future 的值可能现在还不可用（它可能是异步任务的返回结果），我们必须提供一个闭包来接受它的值。

```swift
/// 假设我们从某个 API 返回一个 future 字符串
let futureString: EventLoopFuture<String> = ...

/// 把这个字符串转换成整形
let futureInt = futureString.map { string in
    print(string) // 实际的字符串
    return Int(string) ?? 0
}

/// 我们现在有一个 future 的整数
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

`flatMapThrowing` 方法允许你把一个 future 值转换成另一个值 _或者_ 抛出一个错误。

!!! info "信息"
    因为抛出错误必须在内部创建一个新的 future，所以这个方法前缀为 `flatMap`，即使闭包不接受 future 返回。

```swift
/// 假设我们从某个 API 返回一个 future 字符串。
let futureString: EventLoopFuture<String> = ...

/// 把这个字符串转换成整形
let futureInt = futureString.flatMapThrowing { string in
    print(string) // 实际的字符串
    // 将字符串转换为整数或抛出错误
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// 我们现在有一个 future 的整数
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

`flatMap` 方法允许你将 future 值转换为另一个 future 值。它得到的名称“扁平”映射，因为它允许你避免创建嵌套的未来(例如，`EventLoopFuture<EventLoopFuture<T>>`)。换句话说，它帮助你保持泛型平坦。

```swift
/// 假设我们从某个 API 返回一个 future 字符串。
let futureString: EventLoopFuture<String> = ...

/// 假设我们已经创建了一个 HTTP 客户端。
let client: Client = ... 

/// 将 future 的字符串映射到 future 的响应。
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// 我们现在有一个 future 的回应。
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info "信息"
    如果我们在上面的例子中使用 `map`，我们将会得到：`EventLoopFuture<EventLoopFuture<ClientResponse>>`。

要在 `flatMap` 中调用一个抛出方法，使用 Swift 的 `do` / `catch` 关键字并创建一个 [completed future](#makefuture)。

```swift
/// 假设前面的示例中有 future 的字符串和客户端。
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // 一些同步抛出异常的方法。
        url = try convertToURL(string)
    } catch {
        // 使用事件循环来制作预先完成的 future。
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform
`transform` 方法允许你修改 future 的值，而忽略现有值。这对于转换 `EventLoopFuture<Void>` 的结果特别有用，在这种情况下 future 的实际值并不重要。

!!! tip "建议" 
    `EventLoopFuture<Void>`，有时也被称为信号，是一个 future，它唯一目的是通知你某些异步操作的完成或失败。

```swift
/// 假设我们从某个 API 那里得到了一个 void future
let userDidSave: EventLoopFuture<Void> = ...

/// 将 void future 转换为 HTTP 状态
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

即使我们已经提供了一个可用于 `transform` 的值，但这仍然是一个 _转换_。在所有之前的 future 都完成(或失败)之前，future 不会完成。

### 链接(Chaining)

关于 future 的转换，最重要的一点是它们可以被链接起来。这允许你轻松地表示许多转换和子任务。

让我们修改上面的示例，看看如何利用链接。

```swift
/// 假设我们从某个 API 返回一个 future 字符串
let futureString: EventLoopFuture<String> = ...

/// 假设我们已经创建了一个 HTTP 客户端
let client: Client = ... 

/// 将字符串转换为 url，然后转换为响应
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

在初始调用 map 之后，创建了一个临时的 `EventLoopFuture<URL>`。然后，这个 future 立即平映射到 `EventLoopFuture<Response>`。
    
## Future

让我们看看使用 `EventLoopFuture<T>` 的一些其他方法。

### makeFuture

你可以使用事件循环来创建具有值或错误的预先完成的 future。

```swift
// 创造一个预先成功的 future。
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// 创造一个预先失败的 future。
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete


你可以使用 `whenComplete` 来添加一个回调函数，它将在未来的成功或失败时执行。

```swift
/// 假设我们从某个 API 返回一个 future 字符串
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // 实际的字符串
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note "注意"
    你可以向 future 添加任意数量的回调。
    
### Wait

你可以使用 `.wait()` 来同步等待 future 完成。由于 future 可能会失败，这个调用是可抛出错误的。

```swift
/// 假设我们从某个 API 返回一个 future 字符串
let futureString: EventLoopFuture<String> = ...

/// 阻塞，直到字符串准备好
let string = try futureString.wait()
print(string) /// String
```

`wait()` 方法只能在后台线程或主线程中使用，也就是在 `configure.swift` 中。它 _不能_ 用于事件循环线程，也就是在路由闭包中。

!!! warning "警告"
    试图在事件循环线程上调用 `wait()` 方法将导致断言失败。

    
## Promise

大多数时候，你将转换 Vapor 的 API 返回的 future。然而，在某些情况下，你可能需要创造自己的 promise。

要创建一个 promise，你需要访问一个 `EventLoop`。你可以根据上下文从 `Application` 或 `Request` 获得对事件循环的访问。

```swift
let eventLoop: EventLoop 

// 为某个字符串创建一个新的 promise。
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// 关联成功的 future。
promiseString.succeed("Hello")

// 关联的未来 future。
promiseString.fail(...)
```

!!! info "信息"
    一个 promise 只能完成一次。任何后续的完成都将被忽略。

任何线程都可以完成 promise（`成功`/`失败`）。这就是 promise 需要初始化事件循环的原因。promise 确保完成操作返回到它的事件循环中执行。

## Event Loop

当你的应用程序启动时，它通常会为运行它的 CPU 中的每个核心创建一个事件循环。每个事件循环只有一个线程。如果你熟悉 Node.js 中的事件循环，那么 Vapor 中的事件循环也是类似的。主要的区别是，由于 Swift 支持多线程，Vapor 可以在一个进程中运行多个事件循环。

每次客户端连接到你的服务器时，它将被分配到一个事件循环。从那时起，服务器和客户端之间的所有通信将发生在同一个事件循环上（通过关联，该事件循环的线程）。

事件循环负责跟踪每个连接的客户端的状态。如果客户端有一个等待读取的请求，事件循环会触发读取通知，然后读取数据。一旦整个请求被读取，等待该请求数据的任何 future 都将完成。

在路由闭包中，你可以通过 `Request` 访问当前事件循环。

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning "警告"
    Vapor 预期路由闭包将保持在 `req.eventLoop` 上。如果你跳转线程，你必须确保对 `Request` 的访问和最终的响应都发生在请求的事件循环中。

在路由闭包之外，你可以通过 `Application` 获得一个可用的事件循环。

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

你可以通过 `hop` 来改变一个 future 的事件循环。

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

在事件循环线程上调用阻塞代码会阻止应用程序及时响应传入的请求。阻塞调用的一个例子是 `libc.sleep(_:)`。

```swift
app.get("hello") { req in
    /// 使事件循环的线程进入睡眠状态。
    sleep(5)
    
    /// 一旦线程重新唤醒，返回一个简单的字符串。
    return "Hello, world!"
}
```

`sleep(_:)` 是一个命令，它阻塞当前线程以获得所提供的秒数。如果你直接在事件循环上执行这样的阻塞工作，事件循环将无法在阻塞工作期间响应分配给它的任何其他客户端。换句话说，如果你在一个事件循环中 `sleep(5)`，所有连接到该事件循环的其他客户端（可能有成百上千）将会延迟至少5秒。


确保在后台运行任何阻塞工作。当这项工作以非阻塞方式完成时，使用 promise 来通知事件循环。

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// 在后台线程上分派一些工作
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// 使后台线程进入休眠状态
        /// 这不会影响任何事件循环
        sleep(5)
        
        /// 当“阻塞工作”完成后，
        /// 返回结果.
        return "Hello world!"
    }
}
```

并不是所有的阻塞调用都像 `sleep(_:)` 那样明显。如果你怀疑你正在使用的调用可能是阻塞的，研究方法本身或询问别人。下面的部分将更详细地讨论方法如何阻塞。

### I/O 约束

I/O 约束阻塞意味着等待较慢的资源，如网络或硬盘，这些资源可能比 CPU 慢几个数量级。在等待这些资源时阻塞 CPU 会导致时间的浪费。

!!! danger "危险"
    不要在事件循环中直接进行阻塞 I/O 约束调用.

所有的 Vapor 包都构建在 SwiftNIO 上，并使用非阻塞 I/O。然而，现在有很多 Swift 包和 C 库使用了阻塞 I/O。如果一个函数正在进行磁盘或网络 IO 并使用同步 API（没有使用回调或 future），那么它很有可能是阻塞的。
    
### CPU 约束

请求期间的大部分时间都花在等待数据库查询和网络请求等外部资源加载上。因为 Vapor 和 SwiftNIO 是非阻塞的，所以这种停机时间可以用于满足其他传入的请求。然而，应用程序中的一些路由可能需要执行大量 CPU 约束工作作为请求的结果。

当事件循环处理 CPU 约束的工作时，它将无法响应其他传入的请求。这通常是没问题的，因为 CPU 速度很快，而且 web 应用程序所做的大多数 CPU 工作都是轻量级的。但如果长时间运行 CPU 工作的路由阻止了对更快路由的请求的快速响应，这就会成为一个问题。

识别应用程序中长时间运行的 CPU 工作，并将其转移到后台线程，可以帮助提高服务的可靠性和响应能力。与 I/O 约束的工作相比，CPU 约束的工作更多的是一个灰色区域，最终由你决定在哪里划定界限。

大量 CPU 约束工作的一个常见示例是用户注册和登录期间使用 Bcrypt 哈希。出于安全原因，Bcrypt 被故意设置为非常慢和 CPU 密集型。这可能是一个简单的 web 应用程序所做的最耗费 CPU 的工作。将哈希移到后台线程可以允许 CPU 在计算哈希时交错事件循环工作，从而获得更高的并发性。
