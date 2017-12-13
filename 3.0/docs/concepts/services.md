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

### Environment

Environments indicate the type of deployment/situation in which an application is ran. Environments can be used to change database credentials or API tokens per environment. Development environments often have more debugging features and don't impact real life. A credit card transaction in development is often faked.

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

A single type can conform to multiple protocols, and you might want to register a single service for all those conforming situations.

```swift
protocol Console {
  func write(_ message: String, color: AnsiColor)
}

struct PrintConsole: Console, Logger {
  func write(_ message: String, color: AnsiColor) {
    print(message)
  }

  func log(_ message: String, level: Level) {
    print(message)
  }

  init() {}
}

services.register(
  supports: [Logger.self, Console.self],
  ErrorLogger()
)
```

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

Factorized services get access to the event loop to factorize dependencies.

```swift
services.register { container -> GithubClient in
  // Create an HTTP client for our GithubClient
  let client = try container.make(Client.self, for: GithubClient.self)
  try client.connect(hostname: "github.com", ssl: true)

  return GithubClient(using: client)
}
```

Please do note that we explicitly stated that the `GithubClient` requests an (HTTP) Client. We recommend doing this at all times, so that you leave configuration options open.

## Environments

Vapor 3 supports (custom) environments. By default we recommend (and support) the `.production`, `.development` and `.testing` environments.

You can create a custom environment type as `.custom(<my-environment-name>)`.

```swift
let environment = Environment.custom("staging")
```

Containers give access to the current environment, so libraries may change behaviour depending on the environment.

### Changing configurations per environment

For easy of development, some parameters may and should change for easy of debugging.
Password hashes can be made intentionally weaker in development scenarios to compensate for debug compilation performance, or API tokens may change to the correct one for your environment.

```swift
services.register { container -> BCryptConfig in
  let cost: Int

  switch container.environment {
  case .production:
      cost = 12
  default:
      cost = 4
  }

  return BCryptConfig(cost: cost)
}
```

## Getting a Service

To get a service you need an existing container matching the current EventLoop.
If you're processing a [`Request`](../http/request.md), you should almost always use the Request as a Container type.

```swift
myContainerType.make(Logger.self, for: Request.self)
```
