# Logging 

Vapor 的 `Logging` API 是基于 Apple 的 [SwiftLog](https://github.com/apple/swift-log) 而构建。意味着 Vapor 兼容所有基于 `SwiftLog` 实现的[后端框架](https://github.com/apple/swift-log#backends)。

## Logger

`Logger` 的实例用于输出日志消息，Vapor 提供了一些便捷的方法使用日志记录器。

### Request

每个传入 `Request` 都有一个单独的日志记录器，你可以在该请求中使用任何类型日志。

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

请求的日志记录器都有一个单独的`UUID`用于标识该请求，便于追踪该日志。

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
    日志记录器的元数据仅在调试日志级别或者更低级别显示。
    

### 应用

关于应用程序启动和配置过程中的日志消息，可以使用 `Application` 的日志记录器：

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### 自定义日志记录器

在无法访问 `Application` 或者 `Request` 情况下，你可以初始化一个新的 `Logger`。

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

尽管自定义的日志记录器仍将输出你配置的后端日志记录，但是他们没有附带重要的元数据，比如 `request` 的 `UUID`。所以尽量使用 `application` 或者 `request` 的日志记录器。

## 日志级别(Level)

`SwiftLog` 支持多种日志级别。
<!-- ~~SwiftLog supports several different logging levels.~~ -->

|名称|说明|
|-|-|
|trace|用户级基本输出信息|
|debug|用户级调试信息|
|info|用户级重要信息|
|notice|表明会出现非错误的情形，需要关注处理|
|warning|表明会出现潜在错误的情形，比 `notice` 的消息严重|
|error|指出发生错误事件，但不影响系统的继续运行|
|critical|系统级危险，需要立即关注错误信息并处理|

出现 `critical` 消息时，日志框架可以自由的执行权限更重的操作来捕获系统状态（比如捕获跟踪堆栈）以方便调试。

默认情况下，Vapor 使用 `info` 级别日志。当运行在 `production` 环境时，将使用 `notice` 提高性能。

### 修改日志级别

不管环境模式如何，你都可以通过修改日志级别来增加或减少生成的日志数量。

第一种方法，在启动应用程序时传递可选参数 `--log` 标志：

```sh
vapor run serve --log debug
```

第二种方法，通过设置 `LOG_LEVEL` 环境变量：

```sh
export LOG_LEVEL=debug
vapor run serve
```

这两种方法可以在 Xcode 中编辑 `Run` (scheme)模式进行修改。

## 配置

`SwiftLog` 可以通过每次进程启动 `LoggingSystem` 时进行配置。Vapor 项目通常在 `main.swift` 执行操作。

```swift
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` 是 Vapor 提供的调用方法，它将基于命令行参数和环境变量来配置默认日志处理操作。默认的日志处理操作支持使用 ANSI 颜色将消息输出到终端。

### 自定义操作

你可以覆盖 Vapor 的默认日志处理并注册自己的日志处理操作。

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

所有 SwiftLog 支持的后端框架均可与 Vapor 一起工作。但是，使用命令行参数和环境变量更改日志级别只支持 Vapor 的默认日志处理操作。
