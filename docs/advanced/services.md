# Services

Vapor's `Application` and `Request` are built to be extended by your application and third-party packages. New functionality added to these types are often called services. 

## Read Only

The simplest type of service is read-only. These services consist of computed variables or methods added to either application or request. 

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

Read-only services can depend on any pre-existing services, like `client` in this example. Once the extension has been added, your custom service can be used like any other property on request.

```swift
req.myAPI.foos()
```

## Writable

Services that need state or configuration can utilize `Application` and `Request` storage for storing data. Let's assume you want to add the following `MyConfiguration` struct to your application.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

To use storage, you must declare a `StorageKey`. 

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

This is an empty struct with a `Value` typealias specifying which type is being stored. By using an empty type as the key, you can control what code is able to access your storage value. If the type is internal or private, only your code will be able to modify the associated value in storage.

Finally, add an extension to `Application` for getting and setting the `MyConfiguration` struct.

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

Once the extension is added, you can use `myConfiguration` like a normal property on `Application`.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Lifecycle

Vapor's `Application` allows you to register lifecycle handlers. These let you hook into events such as boot and shutdown.

```swift
// Prints hello during boot.
struct Hello: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }
}

// Add lifecycle handler.
app.lifecycle.use(Hello())
```

## Locks

Vapor's `Application` includes conveniences for synchronizing code using locks. By declaring a `LockKey`, you can get a unique, shared lock to synchronize access to your code. 

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Do something.
}
```

Each call to `lock(for:)` with the same `LockKey` will return the same lock. This method is thread-safe.

For an application-wide lock, you can use `app.sync`. 

```swift
app.sync.withLock {
    // Do something.
}
```

## Request

Services that are intended to be used in route handlers should be added to `Request`. Request services should use the request's logger and event loop. It is important that a request stay on the same event loop or an assertion will be hit when the response is returned to Vapor. 

If a service must leave the request's event loop to do work, it should make sure to return to the event loop before finishing. This can be done using the `hop(to:)` on `EventLoopFuture`. 

Request services that need access to application services, such as configurations, can use `req.application`. Take care to consider thread-safety when accessing the application from a route handler. Generally, only read operations should be performed by requests. Write operations must be protected by locks. 