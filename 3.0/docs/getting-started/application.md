# Application

Every Vapor project has an `Application`. You use the application to run your server and create any services you might need at boot time.

The best place to access the application is in your project's [`boot.swift`](structure.md#bootswift) file.

```swift
import Vapor

public func boot(_ app: Application) throws {
    // your code here
}
```

Unlike some other web frameworks, Vapor doesn't support statically accessing the application. If you need to access it from another class or struct, you should pass through a method or initializer.

!!! info
    Avoiding static access to variables helps make Vapor performant by preventing the need for thread-safe locks or semaphores.


## Services

The application's main function is to boot your server. 

```swift
try app.run()
```

However, the application is also a container. You may use it to create services required to boot your application.

!!! warning
    Do not use the application, or any services created from it, inside a route closure. Use the `Request` to create services instead.

```swift
let client = try app.make(Client.self)
let res = try client.get("http://vapor.codes").wait()
print(res) // Response
```

!!! tip
    It's okay to use `.wait()` here instead of `.map`/`.flatMap` because we are not inside of a route closure.

Learn more about services in [Getting Started &rarr; Services](services.md).
