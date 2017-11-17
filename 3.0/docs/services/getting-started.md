## Configure

You configure the application in the [`configure.swift`](structure.md#configureswift) file. Here you can 
register your own services, or override the ones provided by default.

```swift
import Vapor

public func configure(...) throws {
    services.register {
        let foo = FooService(...)
        return foo
    }
}
```

Later, after your application has booted, you can then request your registered service.

```swift
let foo = try app.make(FooService.self)
```

### Providers

