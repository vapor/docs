# Services

> Services is a framework for managing types and implementations in a type-safe fashion with protocol and environment support.

Let's break that statement up.

## Usage

### Types and implementations

For any given type or protocol you can implement multiple factories and implementations. An example where this is useful is configuration files.

```swift
services.register(HTTPServerConfig.self) { container in
  return HTTPServerConfig(port: 8081)
}
```

The above lines of code register a new `HTTPServerConfig` to the `HTTPServerConfig.self` Type. This means that whenever I, or any code requests an `HTTPServerConfig`, the above function will be executed which will return me a config on port `8081`.

```swift
let serverConfig = try services.make(HTTPServerConfig.self)

print(serverConfig.port) // prints `8081`
```

### Protocols and Environments

In Swift, we prefer working with protocols. This is useful for testing and adds flexibility. Assuming the simple logging protocol and implementation below we'll try to set up a protocol oriented service.

```swift
enum Level {
  case verbose, error
}

protocol Logger {
  func log(_ message: String, level: Level)
}

struct VerboseLogger: Logger {
  init() {}

  func log(_ message: String, level: Level) {
    print(message)
  }
}

struct ErrorLogger: Logger {
  init() {}

  func log(_ message: String, level: Level) {
    if level == .error {
      print(message)
    }
  }
}
```

Using the above code we could use the `VerboseLogger` for development, and error logger on production.

```swift
services.register(Logger.self) { container in
  if container == .development {
    return VerboseLogger()
  } else {
    return ErrorLogger()
  }
}
```

If we set Vapor's environment to development we'll get an instance of `VerboseLogger` and otherwise we'll get an `ErrorLogger`.

```swift
let logger = container.make(Logger.self, for: Request.self)
logger.log("hello", level: .verbose) // only logs on development
```

## Containers

Containers are types that contain the current context. They have access to the services, environment, configuration and [EventLoop](async.md) and can use these to `.make()` new service types.

The factory method registered to a service will get access to the container's Context during the creation of type.

There are a few containers that are often accessed, the primary `Container` type for Vapor users is [`Request`](../http/request.md), which can be accessed in every [`Route`](../routing/route.md).
