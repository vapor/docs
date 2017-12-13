# Services

Services is a framework for managing types and implementations in a type-safe fashion with protocol and environment support.

The Services framework is designed to be thread unsafe. The framework aims to guarantee that a service exists on the same [EventLoop](../async/eventloop.md) it was created from and will be used on.

## Glossary

### Container

Containers are [EventLoops](../async/eventloop.md) that can create and cache services.

[`Request`](../http/request.md) is the most common `Container` type, which can be accessed in every [`Route`](../getting-started/routing.md).

### EphemeralContainer

EphemeralContainers are containers that are short-lived. Their cache does not stretch beyond a short lifecycle. The most common EphemeralContainer is an [HTTP Request](../http/request.md) which lives for the duration of the route handler.

### Service

Services are a type that can be requested from a Container. They are registered as part of the application setup.

Services are registered to a matching type or protocol it can represent, including it's own concrete type.

Services are registered to a blueprint before the [`Application`](../getting-started/application.md) is initialized. Together they make up the blueprint that Containers use to create an individual Service.

## Registering

Services are registered as a concrete (singleton) type or factories. Singleton types should be a struct, but can be a class.

To create an empty list of Services you can call the initializer without parameters

```swift
var services = Services()
```

The Vapor framework has a default setup with the most common (and officially supported) Services already registered.

```swift
var services = Services.default()
```

### Concrete implementations

A common use case for registering a struct is for registering configurations.
Vapor 3 configurations are _always_ a concrete struct type. Registering a concrete type is simple:

```swift
struct EmptyService {}

services.register(EmptyService())
```

### Singletons

Singleton classes _must_ be thread-safe to prevent crashes. If you want your class to be a singleton type (across all threads):

```swift
final class SingletonService {
  init() {}
}

services.register(isSingleton: true, SingletonService())
```

Assuming the above service, you can now make this service from a container. The global container in Vapor is `Application` which *must not* be used within routes.

```swift
let app = try Application(services: services)
let emptyService = app.make(EmptyService.self)
```

### Protocol conforming services

Often times when registering a service is conforms to one or more protocols for which it can be used. This is one of the more widely used use cases for Services.

```swift
enum Level {
  case verbose, error
}

protocol Logger {
  func log(_ message: String, level: Level)
}

struct PrintLogger: Logger {
  init() {}

  func log(_ message: String, level: Level) {
    print(message)
  }
}

services.register(Logger.self, PrintLogger())
```

The above can be combined with `isSingleton: true`

### Registering multiple conformances

A sing

### Registering for a specific requester

Sometimes, the implementation should change depending on the user. A database connector might need to run over a VPN tunnel, redis might use an optimized local loopback whilst the default implementation is a normal TCP socket.

Other times, you simply want to change the log destination depending on the type that's logging (such as logging HTTP errors differently from database errors).

This comes in useful when changing configurations per situation, too.

```swift
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

// Only log errors
services.register(Logger.self, ErrorLogger())

// Except the router, do log not found errors verbosely
services.register(Logger.self, PrintLogger(), for: Router.self)
```

### Factorized services

Some services have dependencies. An extremly useful use case is TLS, where the implementation is separated from the protocol. This allows users to create a TLS socket to connect to another host with without relying on a specific implementation. Vapor uses this to better integrate with the operating system by changing the default TLS implementation from OpenSSL on Linux to the Transport Security Framework on macOS and iOS.

```swift
```

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

There are a few containers that are often accessed, the primary `Container` type for Vapor users is
