# Application

Every Vapor project has an `Application`. You use the application to create any services
you might need while developing.

The best place to access the application is in your project's [`boot.swift`](structure.md#bootswift) file.

```swift
import Vapor

public func boot(_ app: Application) throws {
    // your code here
}
```

You can also access the application from your [`routes.swift`](structure.md#routesswift) file. It's stored
as a property there.

```swift
import Vapor

final class Routes: RouteCollection {
    ...
}
```

Unlike some other web frameworks, Vapor doesn't support statically accessing the application.
If you need to access it from another class or struct, you should pass through a method or initializer.

!!! info
    Avoiding static access to variables helps make Vapor performant by preventing
    the need for thread-safe locks or semaphores.


## Services

The application's main function is to make services. For example, you might need a `BCryptHasher` to hash
some passwords before storing them in a database. You can use the application to create one.

```swift
import BCrypt

let bcryptHasher = try app.make(BCryptHasher.self)
```

Or you might use the application to create an HTTP client.

```swift
let client = try app.make(Client.self)
let res = client.get("http://vapor.codes")
```

Learn more about services in [Services &rarr; Getting Started](../services/getting-started.md).
