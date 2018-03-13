# Services

Services is a framework for creating things you need in your application in a type-safe fashion with protocol and environment support.

The Services framework is designed to be thread unsafe. The framework aims to guarantee that a service exists on the same [EventLoop](../async/eventloop.md) it was created from and will be used on.

## Glossary

### Container

Containers are [EventLoops](../async/eventloop.md) that can create and cache services.

[`Request`](../http/request.md) is the most common `Container` type, which can be accessed in every [`Route`](../getting-started/routing.md).

Containers cache instances of a given service (keyed by the requested protocol) on a per-container basis.

1. Any given container has its own cache. No two containers will ever share a service instance, whether singleton or not.
2. A singleton service is chosen and cached only by which interface(s) it supports and the service tag.
There will only ever be one instance of a singleton service per-container, regardless of what requested it.
3. A normal service is chosen and cached by which interface(s) it supports, the service tag, and the requesting client interface.
There will be as many instances of a normal service per-container as there are unique clients requesting it.
(Remembering that clients are also interface types, not instances - that's the `for:` parameter to `.make()`)

### EphemeralContainer

EphemeralContainers are containers that are short-lived.
Their cache does not stretch beyond a short lifecycle.
The most common EphemeralContainer is an [HTTP Request](../http/request.md) which lives for the duration of the route handler.

### Service

Services are a type that can be requested from a Container. They are registered as part of the application setup.

Services are registered to a matching type or protocol it can represent, including it's own concrete type.

Services are registered to a blueprint before the [`Application`](../getting-started/application.md) is initialized. Together they make up the blueprint that Containers use to create an individual Service.

### Environment

Environments indicate the type of deployment/situation in which an application is ran. Environments can be used to change database credentials or API tokens per environment automatically.

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

services.instance(EmptyService())
```

### Singletons

Singleton services (which declare themselves, or were registered, as such) are cached on a per-container basis, but the singleton cache ignores which Client is requesting the service (whereas the normal cache does not).

Singleton classes _must_ be thread-safe to prevent crashes. If you want your class to be a singleton type (across all threads):

```swift
final class SingletonService {
  init() {}
}

services.instance(isSingleton: true, SingletonService())
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

services.instance(Logger.self, PrintLogger())
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

services.instance(
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
services.instance(Logger.self, ErrorLogger())

// Except the router, do log not found errors verbosely
services.instance(Logger.self, PrintLogger(), for: Router.self)
```

### Factorized services

Some services have dependencies. An extremly useful use case is TLS, where the implementation is separated from the protocol. This allows users to create a TLS socket to connect to another host without relying on a specific implementation. Vapor uses this to better integrate with the operating system by changing the default TLS implementation from OpenSSL on Linux to the Transport Security Framework on macOS and iOS.

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
// ErrorLogger
let errorLogger = myContainerType.make(Logger.self, for: Request.self)

// PrintLogger
let printLogger = myContainerType.make(Logger.self, for: Router.self)
```
