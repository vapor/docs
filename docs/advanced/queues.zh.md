# 队列

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) 是一个纯 Swift 队列系统，它允许你将任务责任转移给一个辅助 worker。

这个包可以很好地完成以下任务：

- 在主请求线程外发送电子邮件
- 执行复杂或耗时的数据库操作
- 确保 job 的完整性和弹性
- 通过延迟非关键处理来加快响应时间
- 调度 job 在特定时间发生

这个包类似于 [Ruby Sidekiq](https://github.com/mperham/sidekiq)。它提供以下功能：
 
- 安全处理托管提供商发送的指示关闭、重启或新部署的 `SIGTERM` 和 `SIGINT` 信号。
- 不同的队列优先级。例如，可以指定在电子邮件队列上运行一个队列 job，在数据处理队列上运行另一个 job。
- 实现可靠的队列进程帮助处理意外故障。
- 包含一个 `maxRetryCount` 特性，该特性将重复执行任务，直到任务成功，直到指定的计数。
- 使用 NIO 将所有可用的内核和 EventLoops 用于 job。
- 允许用户调度重复任务

目前，队列有一个官方支持的驱动程序，它与主协议接口：

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues 也有基于社区的驱动程序：
- [QueuesMongoDriver](https://github.com/vapor-community/queues-mongo-driver)
- [QueuesFluentDriver](https://github.com/m-barthelemy/vapor-queues-fluent-driver)

!!! Tip
    你不应该直接安装 `vapor/queues` 包，除非你正在构建一个新的驱动程序。安装其中一个驱动软件包即可。

## 入门

让我们看看如何使用队列。

### Package

使用队列的第一步是在 SwiftPM 文件中添加一个驱动程序作为项目的依赖项。在本例中，我们将使用 Redis 驱动程序。

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

如果你直接在 Xcode 中编辑清单文件，它会在文件保存时自动获取更改并获取新的依赖项。否则，从终端运行 `swift package resolve` 命令以获取新的依赖项。

### 配置

下一步是在 `configure.swift` 文件中配置队列，我们将使用 Redis 库作为示例：

```swift
try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### 注册一个 `Job`

在为 job 建模后，你必须将其添加到配置部分中，如下所示：

```swift
// 注册 Job
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Worker 作为进程运行

要启动新的队列 worker，请在终端运行 `vapor run queues`。 你还可以指定一个特定类型的 worker 来运行 `vapor run queues --queue emails`。

!!! Tip
    生产环境应该保持 worker 一直运行。咨询你的托管提供商，了解如何保持长时间运行的进程处于活动状态。例如，Heroku 允许你在 Procfile 中指定这样的 “worker” dynos：`worker: Run queues`。有了这个，你可以在仪表板/资源选项卡上启动 worker，或者使用 `heroku ps:scale worker=1`（或首选的任何数量的 dynos）。

### 进程中运行 Worker

要在与你的应用程序相同的进程中运行 worker（而不是启动一个完整的单独服务器来处理它），请调用 `Application` 上的便利方法：

```swift
try app.queues.startInProcessJobs(on: .default)
```

要在进程中运行调度 job，请调用以下方法：

```swift
try app.queues.startScheduledJobs()
```

!!! Warning
    如果你不通过命令行或进程内 worker 启动队列，job 将不会派发。

## `Job` 协议

Job 由 `Job` 或 `AsyncJob` 协议定义。

### 建模 `Job` 对象：

```swift
import Vapor 
import Foundation 
import Queues 

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // 这是你要发送电子邮件的位置
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // 如果你不想处理错误，只需返回一个 future 对象。你也可以完全省略此功能。
        return context.eventLoop.future()
    }
}
```

如果使用 `async`/`await`，你应该使用 `AsyncJob`：

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        // 这是你要发送电子邮件的位置
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        // 如果你不想处理错误，只需 return。你也可以完全省略此功能。
    }
}
```

!!! Info
    确保你的 `Payload` 类型遵循 `Codable` 协议。
!!! Tip
    不要忘记按照**入门**中的说明将此 job 添加到你的配置文件中。

## 派发 Job

要派发队列 job，你需要访问 `Application` 或者 `Request` 的实例。你很可能会在路由内派发 job：

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}

// 或

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"))
    return "done"
}
```

相反，如果你需要从 `Request` 对象不可用的上下文中分派 job (例如，从 `Command` 中)，你需要使用 `Application` 对象中的 `queues` 属性，例如:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue
            .dispatch(
                EmailJob.self, 
                .init(to: "email@email.com", message: "message")
            )
    }
}
```


### 设置 `maxRetryCount`

如果你指定 `maxRetryCount`，job 将在出错时自动重试。例如：

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}

// 或

app.get("email") { req async throws -> String in
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3)
    return "done"
}
```

### 指定延迟

还可以将 job 设置为仅在某个特定 `Date` 过后运行。要指定延迟，将 `Date` 传入 `Dispatch` 中的 `delayUntil` 参数中：

```swift
app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 一天
    try await req.queue.dispatch(
        EmailJob.self, 
        .init(to: "email@email.com", message: "message"),
        maxRetryCount: 3,
        delayUntil: futureDate)
    return "done"
}
```

如果 job 在其延迟参数之前出队，则该 job 将由驱动程序重新排队。 

### 指定优先级

根据你的需要，可以将 job 分为不同的队列类型/优先级。例如，你可能想要打开一个 `email` 队列和一个 `background-processing` 队列来对 job 进行排序。

从扩展 `QueueName` 开始：

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
}
```

然后，在检索 `jobs` 对象时指定队列类型：

```swift
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 一天
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}

// 或

app.get("email") { req async throws -> String in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // 一天
    try await req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        )
    return "done"
}
```

当从 `Application` 对象内部访问时，你应该这样做:

```swift
struct SendEmailCommand: AsyncCommand {
    func run(using context: CommandContext, signature: Signature) async throws {
        context
            .application
            .queues
            .queue(.emails)
            .dispatch(
                EmailJob.self, 
                .init(to: "email@email.com", message: "message"),
                maxRetryCount: 3,
                delayUntil: futureDate
            )
    }
}
```

如果未指定队列，则 job 将在 `default` 队列上运行。确保按照**入门**中的说明为每种队列类型启动 worker。

## 调度 Job

Queues 包还允许你安排在特定时间点发生的 job。

### 启动调度 worker

调度程序需要一个独立的 worker 进程来运行，类似于队列 worker 进程。可以通过以下命令启动 worker：

```sh
swift run Run queues --scheduled
```

!!! Tip
    生产环境应该保持 worker 一直运行。请咨询你的服务托管提供商，了解如何使长时间运行的进程保持活动状态。例如，Heroku 允许你在 Procfile 中像这样指定  “worker” dynos：`worker: Run queues --scheduled`

### 创建一个 `ScheduledJob`

首先，首先创建一个新的 `ScheduledJob` 或者 `AsyncScheduledJob`：

```swift
import Vapor
import Queues

struct CleanupJob: ScheduledJob {
    // 如果你需要，可以通过依赖注入在这里添加额外的服务。

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // 在这里做一些工作，也许队列等待另一个 job。
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct CleanupJob: AsyncScheduledJob {
    // 如果你需要，可以通过依赖注入在这里添加额外的服务。

    func run(context: QueueContext) async throws {
        // 在这里做一些工作，也许队列等待另一个 job。
    }
}
```

然后，在你的配置代码中，注册调度的 job：

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

上述示例中的 job 将在每年5月23日中午12:00运行。

!!! Tip
    调度程序采用你服务器的时区。

### 可用的构建器方法

在调度程序上可以调用五个主要方法，每个方法都会创建其各自的包含更多辅助方法的构建器对象。你应该继续构建一个调度器对象，直到编译器没有向你发出有关未使用结果的警告。有关所有可用方法，请参见下文：

| 辅助函数 | 可用修饰符                   | 描述                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | 运行 job 的月份。返回一个 `Monthly` 对象以进行进一步构建。|
| `monthly()`     | `on(_ day: Day) -> Daily`             | 运行 job 的日期。返回用于进一步构建的 `Daily` 对象。|
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | 运行 job 的星期。返回一个 `Daily` 对象。|
| `daily()`       | `at(_ time: Time)`                    | 运行 job 的时间。链中的最终方法。|
|                 | `at(_ hour: Hour24, _ minute: Minute)`| 运行 job 的小时和分钟。链中的最终方法。|
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` |运行 job 的小时、分钟和时间段。链中的最终方法。|
| `hourly()`      | `at(_ minute: Minute)`                 |运行 job 的分钟。链中的最终方法。|

### 可用辅助函数

队列附带了一些辅助函数枚举以使调度更加容易：

| 辅助函数 | 辅助函数枚举                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

要使用辅助枚举，请在辅助函数上调用适当的修饰符并传递值。例如：

```swift
// 每年一月
.yearly().in(.january)

// 每月第一天
.monthly().on(.first)

// 每周周日
.weekly().on(.sunday)

// 每天午夜
.daily().at(.midnight)
```

## 事件委托

Queues 包允许你指定 `JobEventDelegate` 对象， 当 worker 对 job 执行操作时接收通知。这可用于监控、追踪或报警等目的。

首先，对象需要遵循 `JobEventDelegate` 协议并实现所需的方法

```swift
struct MyEventDelegate: JobEventDelegate {
    /// 当 job 从路由中分派给队列工作者时调用
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// 当 job 放入处理队列并开始工作时调用
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// 当 job 完成处理并从队列中删除时调用
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    /// 当 job 完成处理但出现错误时调用
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
```

然后，将其添加到你的配置文件中：

```swift
app.queues.add(MyEventDelegate())
```

有许多第三方包使用委托功能来提供对队列工作额外的观察：

- [QueuesDatabaseHooks](https://github.com/vapor-community/queues-database-hooks)
- [QueuesDash](https://github.com/gotranseo/queues-dash)