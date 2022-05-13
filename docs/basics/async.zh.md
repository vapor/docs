# Async

## Async Await

Swift 5.5 在语言层面上以 `async`/`await` 的形式引进了并发性。它提供了优秀的方式去处理异步在 Swift 以及 Vapor 应用中。

Vapor 是在 [SwiftNIO](https://github.com/apple/swift-nio.git) 的基础上构建的, SwiftNIO 为低层面的异步编程提供了基本类型。这些类型曾经是(现在依然是)贯穿整个 Vapor 在 `async`/`await` 到来之前。现在大部分代码可以用 `async`/`await` 编写来代替 `EventLoopFuture`。这将简化您的代码，使其更容易推理。

现在大部分的 Vapor 的 APIs 同时提供 `EventLoopFuture` and `async`/`await` 两个版本供你选择。通常，你应该只选择一种编程方式在单个路由 handler 中，而不应该混用。对于应该显示控制 event loops，或者非常需要高性能的应用，应该继续使用 `EventLoopFuture` 在自定义运行器被实现之前(until custom executors are implemented)。 对于其他应用，你应该使用 `async`/`await` 因为它的好处、可读性和可维护性远远超过了任何小的性能损失。

### 迁徙到 async/await

为了适配 async/await 这里有几个步骤需要做。第一步，如果你使用 macOS 你必须使用 macOS 12 Monterey 或者更高以及 Xcode13.1 或者更高。 对于其他平台你需要运行 Swift5.5 或者更高，然后情确认你已经更新了所有依赖。

在你的 Package.swift, 在第一行把 swift-tools-version 设置为 5.5：

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

接下来，设置 platform version 为 macOS 12：

```swift
    platforms: [
       .macOS(.v12)
    ],
```

最后 更新 `Run` 目标让它变成一个可运行的目标：

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

注意：如果你部署在Linux环境请确保你更新到了最新的Swift版本。比如在 Heroku 或者在你的 Dockerfile。举个例子你的 Dockerfile 应该变为：

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

现在你可以迁徙现存的代码。通常返回 `EventLoopFuture` 的方法现在变为返回 `async`。比如：

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

### 使用新旧api

如果你遇到还未支持 `async`/`await` 的API，你可以调用 `.get()` 方法来返回一个 `EventLoopFuture`。

比如

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

可以变为

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

如果你需要反过来，你可以把

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

你可能已经注意到在 Vapor 中一些API返回一个 `EventLoopFuture` 的泛型。如果这是你第一次听到这个特性，它们一开始可能看起来有点令人困惑。但是别担心这个手册会教你怎么利用这些强大的API。

Promises 和 futures 是相关的, 但是截然不同的类型。

|类型|描述|是否可修改|
|-|-|-|
|`EventLoopFuture`|代表一个现在还不可用的值|read-only|
|`EventLoopPromise`|一个可以异步提供值的promise|read/write|


Futures 是基于回调的异步api的替代方案。可以以简单的闭包所不能的方式进行链接和转换。

## 转换

就像Swift中的可选选项和数组一样，futures 可以被映射和平映射。这些是你在 futures 中最基本的操作。

|method|argument|description|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Maps a future value to a different value.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Maps a future value to a different value or an error.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Maps a future value to different _future_ value.|
|[`transform`](#transform)|`U`|Maps a future to an already available value.|

如果你看一下 `map` 和 `flatMap` 在 `Optional<T>` 和 `Array<T>` 中的方法签名(method signatures)。你会看到他们和在 `EventLoopFuture<T>` 中的方法非常相似。

### map

`map` 方法允许你把一个未来值转换成另外一个值。 因为这个未来的值可能现在还不可用，我们必须提供一个闭包来接受它的值。

```swift
/// 假设我们将来从某些API得到一个字符串。
let futureString: EventLoopFuture<String> = ...

/// 把这个字符串转换成整形
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

`flatMapThrowing` 方法允许你把一个未来值转换成另一个值或者抛出一个错误。

!!! 信息
    因为抛出错误必须在内部创建一个新的future，所以这个方法前缀为 `flatMap`，即使闭包不接受future返回。

```swift
/// 假设我们将来从某些API得到一个字符串。
let futureString: EventLoopFuture<String> = ...

/// 把这个字符串转换成整形
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // 将字符串转换为整数或抛出错误
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

flatMap方法允许你将未来值转换为另一个未来值。它得到的名称“扁平”映射，因为它允许你避免创建嵌套的未来(例如，`EventLoopFuture<EventLoopFuture<T>>`)。换句话说，它帮助您保持泛型平坦。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! 信息
    如果我们在上面的例子中使用 `map`，我们将会得到： `EventLoopFuture<EventLoopFuture<ClientResponse>>`。

要在 `flatMap` 中调用一个抛出方法，使用Swift的 `do` / `catch` 关键字并创建一个[completed future](#makefuture)。
To call a throwing method inside of a `flatMap`, use Swift's `do` / `catch` keywords and create a [completed future](#makefuture).

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform
`transform` 方法允许您修改 future 的值，而忽略现有值。这对于转换 `EventLoopFuture<Void>` 的结果特别有用，在这种情况下未来的实际值并不重要。

!!! 提示
    `EventLoopFuture<Void>`， 有时也被称为信号，它的唯一目的是通知您某些异步操作的完成或失败。

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

即使我们提供了一个已经可用的值为 `transform`，它仍然是一个 __transformation__ 。直到所有先前的 future 都完成(或失败)，future 才会完成。

### 链接(Chaining)

关于 transformations，最重要的一点是它们可以被链接起来。这允许您轻松地表示许多转换和子任务。

让我们修改上面的示例，看看如何利用链接。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
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

在初始调用 map 之后，创建了一个临时的 `EventLoopFuture<URL>`。然后，这个future立即平映射(flat-mapped)到 `EventLoopFuture<Response>`
    
## Future

让我们看看使用 `EventLoopFuture<T>` 的一些其他方法。

### makeFuture

You can use an event loop to create pre-completed future with either the value or an error.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete


你可以使用 `whenComplete` 来添加一个回调函数，它将在未来的成功或失败时执行。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    您可以向 future 添加任意数量的回调。
    
### Wait

您可以使用 `.wait()` 来同步等待future完成。由于future可能会失败，这个调用是可抛出错误的。

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()` 只能在后台线程或主线程中使用，也就是在 `configure.swift` 中。它不能在事件循环线程(event loop)上使用，也就是在路由闭包中。

!!! 警告
    试图在事件循环线程上调用 `wait()` 将导致断言失败。

    
## Promise

大多数时候，您将转换 Vapor 的 api 返回的 futures。然而，在某些情况下，你可能需要创造自己的 promise。

要创建一个 promise，你需要访问一个 `EventLoop`。你可以根据上下文(context)从 `Application` 或 `Request` 获得一个 event loop。

```swift
let eventLoop: EventLoop 

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    一个 promise 只能 completed 一次。任何后续的 completions 都将被忽略。

promises 可以从任何线程 completed(`succeed` / `fail`)。这就是为什么 promises 需要初始化一个 event loop。promises 确保完成操作(completion action)返回到其 event loop 中执行。

## Event Loop

当应用程序启动时，它通常会为运行它的CPU中的每个核心创建一个 event loop。每个 event loop 只有一个线程。如果您熟悉 Node.js 中的 event loops，那么 Vapor 中的 event loop也是类似的。主要的区别是 Vapor 可以在一个进程(process)中运行多个 event loop，因为 Swift 支持多线程。

每次客户端连接到服务器时，它将被分配给一个event loops。从这时候开始，服务器和客户端之间的所有通信都将发生在同一个 event loop 上(通过关联，该 event loop 的线程)。

event loop 负责跟踪每个连接的客户机的状态。如果客户端有一个等待读取的请求，event loop 触发一个读取通知，然后数据被读取。一旦读取了整个请求，等待该请求数据的任何 futures 都将完成。

在路由闭包中，你可以通过 `Request` 访问当前事件循环。

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor 预期路由闭包(route closures)将保持在 `req.eventLoop` 上。如果您跳转线程，您必须确保对`Request`的访问和最终的响应都发生在请求的 event loop 中。

在路由闭包(route closures)之外，你可以通过 `Application` 获得一个可用的event loops。
Outside of route closures, you can get one of the available event loops via `Application`. 

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

你可以通过 `hop` 来改变一个 future 的 event loop。

```swift
futureString.hop(to: otherEventLoop)
```

## Blocking

在 event loop 线程上调用阻塞代码会阻止应用程序及时响应传入请求。阻塞调用的一个例子是' libc.sleep(_:) '。

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)` 是一个命令，用于阻塞当前线程的秒数。如果您直接在 event loop 上执行这样的阻塞工作，event loop 将无法在阻塞工作期间响应分配给它的任何其他客户端。换句话说，如果你在一个 event loop 上调用 `sleep(5)`，所有连接到该 event loop 的其他客户端(可能是数百或数千)将延迟至少5秒。

确保在后台运行任何阻塞工作。当这项工作以非阻塞方式完成时，使用 promises 来通知 event loop。

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

并不是所有的阻塞调用都像 `sleep(_:)` 那样明显。如果你怀疑你正在使用的调用可能是阻塞的，研究方法本身或询问别人。下面的部分将更详细地讨论方法如何阻塞。

### I/O 约束

I/O 约束阻塞意味着等待较慢的资源，如网络或硬盘，这些资源可能比 CPU 慢几个数量级。在等待这些资源时阻塞 CPU 会导致时间的浪费。

!!! danger
    不要在事件循环中直接进行阻塞I/O约束调用.

所有的 Vapor 包都构建在 SwiftNIO 上，并使用非阻塞 I/O。然而，现在有很多 Swift 包和 C 库使用了阻塞 I/O。如果一个函数正在进行磁盘或网络 IO 并使用同步 API (没有使用 callbacks 或 future)，那么它很有可能是阻塞的。
    
### CPU 约束

请求期间的大部分时间都花在等待数据库查询和网络请求等外部资源加载上。因为 Vapor 和 SwiftNIO 是非阻塞的，所以这种停机时间可以用于满足其他传入请求。然而，应用程序中的一些路由可能需要执行大量 CPU 约束的工作。

当 event loop 处理CPU约束的工作时，它将无法响应其他传入请求。这通常是没问题的，因为CPU是快速的，大多数CPU工作是轻量级的web应用程序。但是，如果需要大量CPU资源的路由阻止了对更快路由的请求的快速响应，这就会成为一个问题。

识别应用程序中长时间运行的CPU工作，并将其转移到后台线程，可以帮助提高服务的可靠性和响应能力。与I/O约束的工作相比，CPU约束的工作更多的是一个灰色区域，最终由您决定在哪里划定界限。

大量CPU约束工作的一个常见示例是用户注册和登录期间的Bcrypt哈希。出于安全原因，Bcrypt被故意设置为非常慢和CPU密集型。这可能是一个简单的web应用程序所做的最耗费CPU的工作。将哈希移到后台线程可以允许CPU在计算哈希时交错事件循环工作，从而获得更高的并发性。
