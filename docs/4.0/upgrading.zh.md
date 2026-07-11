# 升级到 4.0

本指南向你展示如何将现有的 Vapor 3.x 项目升级到 4.x。本指南尝试涵盖 Vapor 所有的官方软件包以及一些常用的 provider。如果你发现有任何遗漏，[Vapor 的团队聊天室](https://discord.gg/vapor)是寻求帮助的好地方。也欢迎提交 issue 和 pull request。

## 依赖

要使用 Vapor 4，你需要 Xcode 11.4 和 macOS 10.15 或更高版本。

文档中的安装章节会详细介绍如何安装依赖项。

## Package.swift

升级到 Vapor 4 的第一步是更新你软件包的依赖项。下面是一个已升级的 Package.swift 文件示例。你也可以查看更新后的[模板 Package.swift](https://github.com/vapor/template/blob/main/Package.swift)。

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

已为 Vapor 4 升级的所有软件包，其主版本号都将加一。

!!! warning
    由于 Vapor 4 的部分软件包尚未正式发布，因此使用了 `-rc` 预发布标识符。

### 旧的软件包

一些 Vapor 3 软件包已被弃用，例如：

- `vapor/auth`：现已包含在 Vapor 中。
- `vapor/core`：已被拆分吸收到多个模块中。
- `vapor/crypto`：已被 SwiftCrypto 取代（现已包含在 Vapor 中）。
- `vapor/multipart`：现已包含在 Vapor 中。
- `vapor/url-encoded-form`：现已包含在 Vapor 中。
- `vapor-community/vapor-ext`：现已包含在 Vapor 中。
- `vapor-community/pagination`：现已成为 Fluent 的一部分。
- `IBM-Swift/LoggerAPI`：已被 SwiftLog 取代。

### Fluent 依赖

`vapor/fluent` 现在必须作为一个独立的依赖项添加到你的依赖项列表和 target 中。所有特定于数据库的软件包都添加了 `-driver` 后缀，以明确它们对 `vapor/fluent` 的依赖关系。

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
```

### 平台

Vapor 的软件包清单现在明确支持 macOS 10.15 及更高版本。这意味着你的软件包也需要指定平台支持。

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor 未来可能会添加更多受支持的平台。只要版本号等于或高于 Vapor 的最低版本要求，你的软件包可以支持这些平台的任意子集。

### Xcode

Vapor 4 使用 Xcode 11 原生的 SPM 支持。这意味着你不再需要生成 `.xcodeproj` 文件。在 Xcode 中打开你项目的文件夹将自动识别 SPM 并拉取依赖项。

你可以使用 `vapor xcode` 或 `open Package.swift` 在 Xcode 中原生打开你的项目。

更新 Package.swift 后，你可能需要关闭 Xcode 并从根目录中清除以下文件夹：

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

一旦你更新后的软件包成功解析，你应该会看到编译错误——可能相当多。别担心！我们会向你展示如何修复它们。

## Run

首先要做的事情是将 Run 模块的 `main.swift` 文件更新为新格式。

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

`main.swift` 文件的内容替代了 App 模块的 `app.swift`，因此你可以删除该文件。

## App 

让我们来看看如何更新基本的 App 模块结构。

### configure.swift

`configure` 方法应改为接受一个 `Application` 实例。

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

下面是一个更新后的 configure 方法示例。

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// 在应用程序初始化之前调用。
public func configure(_ app: Application) throws {
    // 从 `Public/` 目录提供文件服务
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // 配置 SQLite 数据库
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // 配置迁移
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

下面会介绍配置路由、中间件、fluent 等内容的语法变化。

### boot.swift

由于 `configure` 方法现在接受应用程序实例，`boot` 的内容可以放到 `configure` 方法中。

### routes.swift

`routes` 方法应改为接受一个 `Application` 实例。

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

关于路由语法变化的更多信息将在下面介绍。

## Services

Vapor 4 的服务 API 已经过简化，让你更容易发现和使用服务。服务现在作为 `Application` 和 `Request` 上的方法和属性公开，这样编译器就能帮助你使用它们。

为了更好地理解这一点，让我们看几个示例。

```diff
// 将服务器的默认端口更改为 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

服务器配置现在作为 Application 上的简单属性公开，可以被覆盖，而不再需要向 services 注册一个 `NIOServerConfig`。

```diff
// 注册 cors 中间件
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // 创建一个_空的_中间件配置
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

中间件现在作为 Application 上的一个属性公开，可以向其中添加内容，而不再需要创建并向 services 注册一个 `MiddlewareConfig`。

```diff
// 在路由处理程序中发起一个请求。
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

与 Application 一样，Request 也将服务作为简单的属性和方法公开。在路由闭包内部时，应始终使用请求特定的服务。

这种新的服务模式取代了 Vapor 3 中的 `Container`、`Service` 和 `Config` 类型。

### Providers

配置第三方软件包不再需要 provider。每个软件包会转而使用新的属性和方法扩展 Application 和 Request 以进行配置。

来看看 Leaf 在 Vapor 4 中是如何配置的。

```diff
// 使用 Leaf 进行视图渲染。
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

要配置 Leaf，请使用 `app.leaf` 属性。

```diff
// 禁用 Leaf 视图缓存。
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Environment

当前环境（生产、开发等）可以通过 `app.environment` 访问。

### 自定义服务

在 Vapor 3 中遵循 `Service` 协议并注册到 container 的自定义服务，现在可以表示为 Application 或 Request 的扩展。

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

该服务随后可以通过扩展访问，而不再需要 `make`。

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### 自定义 Providers

大多数自定义服务都可以使用上一节所示的扩展方式实现。然而，一些高级的 provider 可能需要挂钩到应用程序生命周期或使用存储属性。

Application 新增的 `Lifecycle` 帮助类型可用于注册生命周期处理程序。

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

要在 Application 上存储值，你可以使用新的 `Storage` 帮助类型。

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

访问 `app.storage` 可以被包装在一个可设置的计算属性中，以创建一个简洁的 API。

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

Vapor 4 现在直接公开 SwiftNIO 的异步 API，不再试图重载 `map` 和 `flatMap` 这样的方法，也不再为 `EventLoopFuture` 之类的类型创建别名。Vapor 3 提供这些重载和别名是为了向后兼容 SwiftNIO 出现之前发布的早期测试版本。为了减少与其他兼容 SwiftNIO 的软件包之间的混淆，并更好地遵循 SwiftNIO 的最佳实践建议，这些重载和别名已被移除。

### 异步命名变化

最明显的变化是 `EventLoopFuture` 的 `Future` 类型别名已被移除。这可以通过查找和替换轻松修复。

此外，NIO 不支持 Vapor 3 添加的 `to:` 标签。鉴于 Swift 5.2 改进后的类型推断，`to:` 现在也不那么必要了。

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

以 `new` 为前缀的方法，比如 `newPromise`，已改为 `make`，以更符合 Swift 的风格。

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` 已不再可用，但可以改用 NIO 的 `mapError` 和 `flatMapErrorThrowing` 等方法。

Vapor 3 中用于组合多个 future 的全局 `flatMap` 方法已不再可用。可以使用 NIO 的 `and` 方法将多个 future 组合在一起来替代。

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // 对 a 和 b 做一些操作。
}
```

### ByteBuffer

许多以前使用 `Data` 的方法和属性现在使用 NIO 的 `ByteBuffer`。这个类型是一种更强大、性能更好的字节存储类型。你可以在 [SwiftNIO 的 ByteBuffer 文档](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/bytebuffer)中阅读更多关于其 API 的内容。

要将 `ByteBuffer` 转换回 `Data`，请使用：

```swift
Data(buffer.readableBytesView)
```

### 抛出错误的 map / flatMap

最困难的变化是 `map` 和 `flatMap` 不能再抛出错误。`map` 有一个可以抛出错误的版本，名为（有点令人困惑）`flatMapThrowing`。然而 `flatMap` 没有可抛出错误的对应版本。这可能需要你重新组织一些异步代码。

不抛出错误的 map 应该可以继续正常工作。

```swift
// 不抛出错误的 map。
futureA.map { a in
    return b
}
```

会抛出错误的 map 必须重命名为 `flatMapThrowing`。

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

不抛出错误的 flat-map 应该可以继续正常工作。

```swift
// 不抛出错误的 flatMap。
futureA.flatMap { a in
    return futureB
}
```

不要在 flat-map 内部抛出错误，而是返回一个 future 错误。如果错误来自另一个会抛出错误的方法，可以在 do / catch 中捕获该错误并作为 future 返回。

```swift
// 将捕获的错误作为 future 返回。
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

会抛出错误的方法调用也可以重构为 `flatMapThrowing`，并使用元组进行链式调用。

```swift
// 将会抛出错误的方法重构为使用元组链式调用的 flatMapThrowing。
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result 是 doSomething 的返回值。
    return futureB
}
```

## 路由

路由现在直接注册到 Application。

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

这意味着你不再需要向 services 注册一个 router。只需将 application 传递给你的 `routes` 方法并开始添加路由即可。`RoutesBuilder` 上可用的所有方法在 `Application` 上都可用。

### 同步内容

解码请求内容现在是同步的。

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

可以通过使用 `.stream` 请求体收集策略注册路由来覆盖此行为。

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // 请求体现在是异步的。
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### 逗号分隔的路径

出于一致性考虑，路径现在必须以逗号分隔，且不能包含 `/`。

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // 处理请求。
}
```

### 路由参数

`Parameter` 协议已被移除，取而代之的是显式命名的参数。这可以防止在中间件和路由处理程序中出现参数重复以及无序获取参数的问题。

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

在模型中使用路由参数的方式在 Fluent 章节中会提到。

## 中间件

`MiddlewareConfig` 已重命名为 `MiddlewareConfiguration`，并现在是 Application 上的一个属性。你可以使用 `app.middleware` 向你的应用添加中间件。

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

中间件不能再通过类型名注册。需要先初始化中间件，然后再注册它。

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

要移除所有默认中间件，请使用以下方式将 `app.middleware` 设置为一个空配置：

```swift
app.middleware = .init()
```

## Fluent

Fluent 的 API 现在与数据库无关。你只需导入 `Fluent`。

```diff
- import FluentMySQL
+ import Fluent
```

### 模型

所有模型现在都使用 `Model` 协议，并且必须是类。

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

所有字段都使用 `@Field` 或 `@OptionalField` 属性包装器声明。

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

模型的 ID 必须使用 `@ID` 属性包装器定义。

```diff
+ @ID(key: .id)
var id: UUID?
```

使用自定义键或类型的标识符的模型必须使用 `@ID(custom:)`。

所有模型都必须静态定义其表名或集合名。

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

所有模型现在都必须有一个空的初始化方法。由于所有属性都使用属性包装器，这个初始化方法可以是空的。

```diff
final class Planet: Model {
+   init() { }
}
```

模型的 `save`、`update` 和 `create` 不再返回模型实例。

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

模型不能再用作路由路径组件。请改用 `find` 和 `req.parameters.get`。

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` 已重命名为 `Model.IDValue`。

模型的时间戳现在使用 `@Timestamp` 属性包装器声明。

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### 关系

关系现在使用属性包装器定义。

Parent 关系使用 `@Parent` 属性包装器，并在内部包含字段属性。传递给 `@Parent` 的 key 应该是数据库中存储该标识符的字段名称。

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Children 关系使用 `@Children` 属性包装器，并带有一个指向相关 `@Parent` 的 key path。

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Siblings 关系使用 `@Siblings` 属性包装器，并带有指向 pivot 模型的 key path。

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Pivot 现在是符合 `Model` 协议的普通模型，包含两个 `@Parent` 关系以及零个或多个额外字段。

### 查询

数据库上下文现在在路由处理程序中通过 `req.db` 访问。

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` 已重命名为 `Database`。

字段的 key path 现在使用 `$` 前缀来指定属性包装器，而不是字段值。

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### 迁移

模型不再支持基于反射的自动迁移。所有迁移都必须手动编写。

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

迁移现在是字符串类型的，与模型解耦，并使用 `Migration` 协议。

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

`prepare` 和 `revert` 方法不再是静态方法。

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

创建 schema builder 现在通过 `Database` 上的一个实例方法完成。

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

`create`、`update` 和 `delete` 方法现在在 schema builder 上调用，方式类似于 query builder 的工作方式。

字段定义现在是字符串类型的，遵循以下模式：

```swift
field(<name>, <type>, <constraints>)
```

请看下面的示例。

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

Schema 的构建现在可以像 query builder 一样进行链式调用。

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Fluent 配置

`DatabasesConfig` 已被 `app.databases` 取代。

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` 已被 `app.migrations` 取代。

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### 仓库

由于 Vapor 4 中服务的工作方式发生了变化，数据库仓库的实现方式也随之改变。你仍然需要一个诸如 `UserRepository` 之类的协议，但不再让一个 `final class` 遵循该协议，而是应该改用一个 `struct`。

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

你还应该移除对 `ServiceType` 的遵循，因为它在 Vapor 4 中已不再存在。
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

取而代之，你应该创建一个 `UserRepositoryFactory`：
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
这个 factory 负责为一个 `Request` 返回一个 `UserRepository`。

下一步是为 `Application` 添加一个扩展来指定你的 factory：
```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

要在 `Request` 内部使用实际的仓库，请为 `Request` 添加此扩展：
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

最后一步是在 `configure.swift` 中指定该 factory
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

现在你可以在路由处理程序中通过 `req.users.all()` 访问你的仓库，并且可以在测试中轻松替换 factory。
如果你想在测试中使用一个模拟的仓库，首先创建一个 `TestUserRepository`
```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

你现在可以在测试中按如下方式使用这个模拟的仓库：
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
