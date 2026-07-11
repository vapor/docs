# 测试

## VaporTesting

Vapor 包含一个名为 `VaporTesting` 的模块，它提供了基于 `Swift Testing` 的测试帮助程序。这些测试辅助程序允许你以编程方式或通过 HTTP 服务器将测试请求发送至 Vapor 应用程序。

!!! note
    对于采用 Swift 并发的新项目或团队，强烈建议使用 `Swift Testing` 而不是 `XCTest`。

### 入门

要使用 `VaporTesting` 模块，请确保它已被添加到你项目的测试 target 中。

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "VaporTesting", package: "vapor"),
        ])
    ]
)
```

!!! warning
    请务必使用与之对应的测试模块，否则可能导致 Vapor 测试失败没有被正确报告。

然后，在你的测试文件顶部添加 `import VaporTesting` 和 `import Testing`。创建带有 `@Suite` 名称的结构体来编写测试用例。

```swift
@testable import App
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Test Stub")
    func stub() async throws {
        // 在这里测试。
    }
}
```

每个标记了 `@Test` 的函数都会在你的应用程序被测试时自动运行。

为了确保你的测试以串行方式运行（例如，在使用数据库进行测试时），请在测试套件声明中包含 `.serialized` 选项：

```swift
@Suite("App Tests with DB", .serialized)
```

### 可测试的应用程序

为了提供简化且标准化的测试搭建与拆卸流程，`VaporTesting` 提供了 `withApp` 帮助函数。此方法封装了 `Application` 实例的生命周期管理，确保应用程序在每个测试中都能被正确初始化、配置和关闭。

将你应用程序的 `configure(_:)` 方法传递给 `withApp` 帮助函数，以确保所有路由都被正确注册：

```swift
@Test func someTest() async throws { 
    try await withApp(configure: configure) { app in
        // your actual test
    }
}
```

#### 发送请求

要向你的应用程序发送测试请求，请使用 `withApp` 方法，并在其内部使用 `app.testing().test()` 方法：

```swift
@Test("Test Hello World Route")
func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

前两个参数是 HTTP 方法和请求的 URL。尾随闭包接受 HTTP 响应，你可以使用 `#expect` 宏来进行验证。

对于更复杂的请求，你可以提供一个 `beforeRequest` 闭包来修改请求头或编码内容。Vapor 的 [Content API](../basics/content.md) 可以在测试请求和响应中使用。

```swift
let newDTO = TodoDTO(id: nil, title: "test")

try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(newDTO)
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let models = try await Todo.query(on: app.db).all()
    #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
})
```

#### 测试方法

Vapor 的测试 API 支持以编程方式并通过实时 HTTP 服务器发送测试请求。你可以通过使用 `testing` 方法来指定你想要使用的方法。

```swift
// 使用程序化测试。
app.testing(method: .inMemory).test(...)

// 通过一个实时的 HTTP 服务器运行测试。
app.testing(method: .running).test(...)
```

默认情况下使用 `inMemory` 选项。

`running` 选项支持传递一个特定的端口来使用。默认情况下使用的是 `8080`。

```swift
app.testing(method: .running(port: 8123)).test(...)
```

#### 数据库集成测试

专门为测试配置数据库，以确保你的正式数据库在测试期间永远不会被使用。例如，当你使用 SQLite 时，你可以在 `configure(_:)` 函数中按如下方式配置你的数据库：

```swift
public func configure(_ app: Application) async throws {
    // 其他所有配置...

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
}
```

!!! warning
    请确保你的测试是针对正确的数据库运行的，以防止意外覆盖你不想丢失的数据。

然后，你可以通过使用 `autoMigrate()` 和 `autoRevert()` 来增强你的测试，以便在测试期间管理数据库模式和数据的生命周期。为此，你应该创建自己的帮助函数 `withAppIncludingDB`，其中包含数据库模式和数据的生命周期：

```swift
private func withAppIncludingDB(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()   
    }
    catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
```

然后在你的测试中使用这个帮助函数：
```swift
@Test func myDatabaseIntegrationTest() async throws {
    try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "hello") { res async in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
} 
```

通过组合使用这些方法，你可以确保每个测试都以一个全新且一致的数据库状态开始，从而使你的测试更加可靠，并减少因遗留数据而导致误报或漏报的可能性。


## XCTVapor

Vapor 包含一个名为 `XCTVapor` 的模块，它提供了基于 `XCTest` 的测试帮助程序。这些测试辅助程序允许你以编程方式或通过 HTTP 服务器将测试请求发送至 Vapor 应用程序。

### 入门

要使用 `XCTVapor` 模块，请确保它已被添加到你项目的测试 target 中。

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

然后，在测试文件的顶部添加 `import XCTVapor`，创建继承于 `XCTestCase` 的子类来编写测试用例。

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
        // 在这里测试。
    }
}
```

当你的应用程序执行测试时，每个以 `test` 开头的函数都会自动运行。

### 可测试的应用程序

使用 `.testing` 环境初始化一个 `Application` 的实例。在此应用程序被销毁之前，你必须调用 `app.shutdown()`。

关闭操作是为了释放应用程序所占用的资源。特别重要的是释放应用程序在启动时请求的线程。如果你在每个单元测试后没有调用 `shutdown()` 方法，可能会在为 `Application` 的新实例分配线程时导致测试套件崩溃，出现先决条件失败。

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

将 `Application` 实例对象作为入参传到 `configure(_:)` 方法来应用你的配置，之后可以应用到任何仅测试的配置。

#### 发送请求

要向你的应用程序发送一个测试请求，请使用 `test` 方法。

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

前两个参数是 HTTP 方法和请求的 URL。后面的尾随闭包接受 HTTP 响应，你可以使用 `XCTAssert` 方法进行验证。

对于更复杂的请求，你可以提供一个 `beforeRequest` 闭包来修改请求头或编码内容。Vapor 的 [Content API](../basics/content.md) 可以在测试请求和响应中使用。

```swift
try app.test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

#### 可测试的方法

Vapor 的测试 API 支持以编程方式并通过实时 HTTP 服务器发送测试请求。
你可以通过使用 `testable` 方法来指定你想要使用的方法。

```swift
// 使用程序化测试。
app.testable(method: .inMemory).test(...)

// 通过一个实时的 HTTP 服务器运行测试。
app.testable(method: .running).test(...)
```

默认情况下使用 `inMemory` 选项。

`running` 选项支持传递一个特定的端口来使用。默认情况下使用的是 `8080`。

```swift
.running(port: 8123)
```
