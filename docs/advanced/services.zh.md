# 服务

Vapor 的 `Application` 和 `Request` 可通过你的应用程序和第三方软件包进行扩展。添加到这些类型的新功能通常称为服务。

## 只读

最简单的服务类型是只读的。这些服务由添加到应用程序或请求的计算变量或方法组成。

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

只读服务可以依赖于任何已经存在的服务，比如本例中的 `client`。一旦添加了扩展，你的自定义服务就可以像使用任何其他请求的属性一样使用。

```swift
req.myAPI.foos()
```

## 可写

需要状态或配置的服务可以利用 `Application` 和 `Request` 存储来存储数据。假设你想将以下 `MyConfiguration` 结构添加到你的应用程序中。

```swift
struct MyConfiguration {
    var apiKey: String
}
```

要使用存储，你必须声明一个 `StorageKey`。

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

这是一个空结构，带有一个 `Value` 类型别名，指定存储的类型。通过使用空类型作为 key，你可以控制哪些代码能够访问存储值。如果类型是内部或私有，则只有你的代码能够修改存储中的关联值。

最后，为 `Application` 添加一个扩展来获取和设置 `MyConfiguration` 结构体。

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

添加扩展后，你就可以像使用 `Application` 的普通属性一样使用 `myConfiguration`。

```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## 生命周期

Vapor 的 `Application` 允许你注册生命周期处理程序。它们允许你连接到诸如启动和关机之类的事件。

```swift
// 启动间打印 Hello!。
struct Hello: LifecycleHandler {
    // 程序启动前调用。
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }
}

// 添加生命周期处理程序。
app.lifecycle.use(Hello())
```

## 锁

Vapor 的 `Application` 包括使用锁同步代码的便利性。通过声明 `LockKey`，你可以获得一个唯一的共享锁来同步对代码的访问。

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Do something.
}
```

每次以相同的 `LockKey` 调用 `lock(for:)` 方法都将返回相同的锁。此方法是线程安全的。

对于应用程序范围的锁，你可以使用 `app.sync`。

```swift
app.sync.withLock {
    // Do something.
}
```

## Request

打算在路由处理中使用的服务应该添加到 `Request` 中。请求服务应该使用请求的记录器和事件循环。请求保持在相同的事件循环中非常重要，否则当响应返回到 Vapor 时会触发一个断言。

如果服务必须离开请求的事件循环才能工作，它应该确保在完成之前返回到事件循环。可以使用 `EventLoopFuture` 上 `hop(to:)` 方法来完成。

需要访问应用服务的请求服务，比如配置，可以使用 `req.application`。从路由处理访问应用程序时，请注意考虑线程安全性。通常，请求只应该执行读操作。写操作必须有锁保护。
