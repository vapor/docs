# Services

Services is a dependency injection (also called inversion of control) framework for Vapor. The services framework allows you to register, configure, and initialize anything you might need in your application.

## Container

Most of your interaction with services will happen through a container. A container is a combination of the following:

- [Services](#services): A collection of registered services.
- [Config](#config): Declared preferences for certain services over others.
- [Environment](#environment): The application's current environment type (testing, production, etc)
- [Worker](async.md#event-loop): The event loop associated with this container.

The most common containers you will interact with in Vapor are:

- `Application`
- `Request`
- `Response`

You should use the `Application` as a container to create services required for booting your app. You should use the `Request` or `Response` containers to create services for responding to requests (in route closures and controllers).

### Make

Making services is simple, just call `.make(_:)` on a container and pass the type you want, usually a protocol like `Client`.

```swift
let client = try req.make(Client.self)
```

You can also specify a concrete type if you know exactly what you want.

```swift
let leaf = try req.make(LeafRenderer.self)
print(leaf) /// Definitely a LeafRenderer

let view = try req.make(ViewRenderer.self)
print(view) /// ViewRenderer, might be a LeafRenderer
```

!!! tip
    Try to rely on protocols over concrete types if you can. This will make testing your code easier (you can easily swap in dummy implementations) and it can help keep your code decoupled.

## Services

The `Services` struct contains all of the services you&mdash;or the service providers you have added&mdash;have registered. You will usually register and configure your services in  [`configure.swift`](structure.md#configureswift).

### Instance

You can register initialized service instances using `.register(_:)`.

```swift
/// Create an in-memory SQLite database
let sqlite = SQLiteDatabase(storage: .memory)

/// Register to sevices.
services.register(sqlite)
```

After you register a service, it will be available for creation by a `Container`. 

```swift
let db = app.make(SQLiteDatabase.self)
print(db) // SQLiteDatabase (the one we registered earlier)
```

### Protocol

When registering services, you can also declare conformance to a particular protocol. You might have noticed that this is how Vapor registers its main router.

```swift
/// Register routes to the router
let router = EngineRouter.default()
try routes(router)
services.register(router, as: Router.self)
```

Since we register the `router` variable with `as: Router.self`, it can be created using either the concrete type or the protocol.

```swift
let router = app.make(Router.self)
let engineRouter = app.make(EngineRouter.self)
print(router) // Router (actually EngineRouter)
print(engineRouter) // EngineRouter
print(router === engineRouter) // true
```

## Environment

The environment is used to dynamically change how your Vapor app behaves in certain situations. For example, you probably want to use a different username and password for your database when your application is deployed. The `Environment` type makes managing this easy.

When you run your Vapor app from the command line, you can pass an optional `--env` flag to specify the environment. By default, the environment will be `.development`.

```sh
swift run Run --env prod
```

In the above example, we are running Vapor in the `.production` environment. This environment specifies `isRelease = true`.

You can use the environment passed into [`configure.swift`](structure.md#configureswift) to dynamically register services.

```swift
let sqlite: SQLiteDatabase
if env.isRelease {
    /// Create file-based SQLite db using $SQLITE_PATH from process env
    sqlite = try SQLiteDatabase(storage: .file(path: Environment.get("SQLITE_PATH")!))
} else {
    /// Create an in-memory SQLite database
    sqlite = try SQLiteDatabase(storage: .memory)
}
services.register(sqlite)
```

!!! info
    Use the static method `Environment.get(_:)` to fetch string values from the process environment.
    
You can also dynamically register services based on environment using the factory `.register(_:)` method.

```swift
services.register { container -> BCryptConfig in
  let cost: Int
  
  switch container.environment {
  case .production: cost = 12
  default: cost = 4
  }
  
  return BCryptConfig(cost: cost)
}
```

## Config

If multiple services are available for a given protocol, you will need to use the `Config` struct to declare which service you prefer.

```sh
ServiceError.ambiguity: Please choose which KeyedCache you prefer, multiple are available: MemoryKeyedCache, FluentCache<SQLiteDatabase>.
```

This is also done in [`configure.swift`](structure.md#configureswift), just use the `config.prefer(_:for:)` method.

```swift
/// Declare preference for MemoryKeyedCache anytime a container is asked to create a KeyedCache
config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

/// ...

/// Create a KeyedCache using the Request container
let cache = req.make(KeyedCache.self)
print(cache is MemoryKeyedCache) // true
```