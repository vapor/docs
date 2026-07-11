# 错误

Vapor 的错误处理基于 Swift 的 `Error` 协议。路由处理可以通过 `throw` 抛出或返回 `EventLoopFuture` 对象。抛出或返回 Swift 的 `Error` 将导致`500`状态响应并记录错误。`AbortError` 和 `DebuggableError` 分别用于更改响应结果和记录日志。错误的处理由 `ErrorMiddleware` 中间件完成。此中间件默认添加到应用程序中，如果需要，可以用自定义逻辑替换

## 中断(Abort)

Vapor 提供了名为 `Abort` 的默认错误结构。该结构遵循 `AbortError` 和 `DebuggableError` 协议。你可以使用 HTTP 状态和可选的失败原因对其进行初始化。

```swift
// 404 错误，默认原因”未找到“。
throw Abort(.notFound)

// 401 错误，自定义错误原因。
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

在旧的异步情况下不支持抛出错误，你必须返回一个 `EventLoopFuture`，就像在 `flatMap` 闭包中一样，你可以返回一个失败的 future。

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor 提供了一个辅助扩展，用于解包具有可选值的 future 对象：`unwrap(or:)`。

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // 非可选，提供给闭包的用户。
}
```

如果 `User.find` 返回 `nil`，future 将因提供的错误而失败。否则，`flatMap` 将提供一个非可选值。如果使用 `async`/`await` 那么你可以正常处理可选值：

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## 中断错误

默认情况下，路由闭包抛出或返回的任何 Swift 的 `Error` 都会导致`500 服务器内部错误`的响应。在调试模式下构建时，`ErrorMiddleware` 中间件将包含错误描述。当项目以发布模式构建时，出于安全原因将其删除。

要配置生成的 HTTP 状态响应或特定错误的原因，请将其遵循 `AbortError` 协议。

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## 调试错误

`ErrorMiddleware` 中间件使用 `Logger.report(error:)` 方法记录路由抛出的错误。此方法将检查是否遵循 `CustomStringConvertible` 和 `LocalizedError` 等协议，以记录可读消息。

要自定义错误日志记录，你可以遵循 `DebuggableError` 协议。该协议包括许多有用的属性，例如唯一标识符、源位置和堆栈跟踪。大多数这些属性都是可选的，这使得采用一致性变得容易。

为了更好的遵循 `DebuggableError` 协议，你的错误应该是一个结构，以便它可以在需要时存储源和堆栈跟踪信息。下面是上述 `MyError` 枚举的示例，更新为使用 `struct` 并捕获错误源信息。

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` 协议有几个其他属性，如 `possibleCauses` 和 `suggestedFixes` 你可以使用它们来提高错误的可调试性。查看协议本身以获取更多信息。

## 错误中间件

`ErrorMiddleware` 是默认添加到应用程序的仅有的两个中间件之一。该中间件将路由处理抛出或返回的 Swift 错误转换为 HTTP 响应。如果没有这个中间件，抛出的错误将导致连接被关闭而没有响应。

要定制 `AbortError` 和 `DebuggableError` 所提供的错误处理之外的错误处理，你可以用自己的错误处理逻辑替换 `ErrorMiddleware` 中间件。要做到这一点，首先通过设置 `app.middleware` 为空删除默认的错误中间件。然后，将你自己的错误处理中间件作为第一个中间件添加到应用程序中。

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

很少有中间件应该放在错误处理中间件*之前*。但 `CORSMiddleware` 中间件不适用该规则。
