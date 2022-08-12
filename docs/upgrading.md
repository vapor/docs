# Upgrading to 4.0

This guide shows you how to upgrade an existing Vapor 3.x project to 4.x. This guide attempts to cover all of Vapor's official packages as well as some commonly used providers. If you notice anything missing, [Vapor's team chat](https://discord.gg/vapor) is a great place to ask for help. Issues and pull requests are also appreciated.

## Dependencies

To use Vapor 4, you will need Xcode 11.4 and macOS 10.15 or greater.

The Install section of the docs goes over installing dependencies.

## Package.swift

The first step to upgrading to Vapor 4 is to update your package's dependencies. Below is an example of an upgraded Package.swift file. You can also check out the updated [template Package.swift](https://github.com/vapor/template/blob/main/Package.swift).

```diff
-// swift-tools-version:4.0
+// swift-tools-version:5.2
 import PackageDescription
 
 let package = Package(
     name: "api",
+    platforms: [
+        .macOS(.v10_15),
+    ],
     dependencies: [
-        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
+        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
-        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
-        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
+        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
     ],
     targets: [
         .target(name: "App", dependencies: [
-            "FluentPostgreSQL", 
+            .product(name: "Fluent", package: "fluent"),
+            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
-            "Vapor", 
+            .product(name: "Vapor", package: "vapor"),
-            "JWT", 
+            .product(name: "JWT", package: "jwt"),
         ]),
-        .target(name: "Run", dependencies: ["App"]),
-        .testTarget(name: "AppTests", dependencies: ["App"])
+        .target(name: "Run", dependencies: [
+            .target(name: "App"),
+        ]),
+        .testTarget(name: "AppTests", dependencies: [
+            .target(name: "App"),
+        ])
     ]
 )
```

All packages that have been upgraded for Vapor 4 will have their major version number incremented by one.

!!! warning
    The `-rc` pre-release identifier is used since some packages of Vapor 4 has not been officially released yet.

### Old Packages

Some packages may not be upgraded yet. If you encounter any, file an issue to let the author know. 

Some Vapor 3 packages have been deprecated, such as:

- `vapor/auth`: Now included in Vapor.
- `vapor/core`: Absorbed into several modules. 
- `vapor/crypto`: Replaced by SwiftCrypto.
- `vapor/multipart`: Now included in Vapor.
- `vapor/url-encoded-form`: Now included in Vapor.
- `vapor-community/vapor-ext`: Now included in Vapor.
- `vapor-community/pagination`: Now part of Fluent.
- `IBM-Swift/LoggerAPI`: Replaced by SwiftLog.

### Fluent Dependency

`vapor/fluent` must now be added as a separate dependency to your dependencies list and targets. All database-specific packages have been suffixed with `-driver` to make the requirement on `vapor/fluent` clear.

```diff
- .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
+ .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
+ .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
```

### Platforms

Vapor's package manifests now explicitly support macOS 10.15 and greater. This means your package will also need to specify platform support. 

```diff
+ platforms: [
+     .macOS(.v10_15),
+ ],
```

Vapor may add additional supported platforms in the future. Your package may support any subset of these platforms as long as the version number is equal or greater to Vapor's minimum version requirements. 

### Xcode

Vapor 4 utilizes Xcode 11's native SPM support. This means you will no longer need to generate `.xcodeproj` files. Opening your project's folder in Xcode will automatically recognize SPM and pull in dependencies. 

You can open your project natively in Xcode using `vapor xcode` or `open Package.swift`. 

Once you've updated Package.swift, you may need to close Xcode and clear the following folders from the root directory:

- `Package.resolved`
- `.build`
- `.swiftpm`
- `*.xcodeproj`

Once your updated packages have resolved successfully you should see compiler errors--probably quite a few. Don't worry! We'll show you how to fix them.

## Run

The first order of business is to update your Run module's `main.swift` file to the new format.

```swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
```

The `main.swift` file's contents replace the App module's `app.swift`, so you can delete that file.

## App 

Let's take a look at how to update the basic App module structure.

### configure.swift

The `configure` method should be changed to accept an instance of `Application`. 

```diff
- public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
+ public func configure(_ app: Application) throws
```

Below is an example of an updated configure method.

```swift
import Fluent
import FluentSQLiteDriver
import Vapor

// Called before your application initializes.
public func configure(_ app: Application) throws {
    // Serves files from `Public/` directory
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Configure migrations
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

Syntax changes for configuring things like routing, middleware, fluent, and more are mentioned below.

### boot.swift

`boot`'s contents can be placed in the `configure` method since it now accepts the application instance.

### routes.swift

The `routes` method should be changed to accept an instance of `Application`.

```diff
- public func routes(_ router: Router, _ container: Container) throws
+ public func routes(_ app: Application) throws
```

More information on changes to routing syntax are mentioned below.

## Services

Vapor 4's services APIs have been simplified to make it easier for you to discover and use services. Services are now exposed as methods and properties on `Application` and `Request` which allows the compiler to help you use them. 

To understand this better, let's take a look at a few examples.

```diff
// Change the server's default port to 8281
- services.register { container -> NIOServerConfig in
-     return .default(port: 8281)
- }
+ app.http.server.configuration.port = 8281
```

Instead of registering a `NIOServerConfig` to services, server configuration is now exposed as simple properties on Application that can be overridden. 

```diff
// Register cors middleware
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .GET, .PATCH, .PUT, .DELETE, .OPTIONS]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
- var middlewares = MiddlewareConfig() // Create _empty_ middleware config
- middlewares.use(corsMiddleware)
- services.register(middlewares)
+ app.middleware.use(corsMiddleware)
```

Instead of creating and registering a `MiddlewareConfig` to services, middleware are now exposed as a property on Application that can be added to.

```diff
// Make a request in a route handler.
- try req.make(Client.self).get("https://vapor.codes")
+ req.client.get("https://vapor.codes")
```

Like Application, Request also exposes services as simple properties and methods. Request-specific services should always be used when inside a route closure.

This new service pattern replaces the `Container`, `Service`, and `Config` types from Vapor 3. 

### Providers

Providers are no longer required to configure third party packages. Each package instead extends Application and Request with new properties and methods for configuration.

Take a look at how Leaf is configured in Vapor 4.

```diff
// Use Leaf for view rendering. 
- try services.register(LeafProvider())
- config.prefer(LeafRenderer.self, for: ViewRenderer.self)
+ app.views.use(.leaf)
```

To configure Leaf, use the `app.leaf` property.

```diff
// Disable Leaf view caching.
- services.register { container -> LeafConfig in
-     return LeafConfig(tags: ..., viewsDir: ..., shouldCache: false)
- }
+ app.leaf.cache.isEnabled = false
```

### Environment

The current environment (production, development, etc) can be accessed via `app.environment`. 

### Custom Services

Custom services conforming to the `Service` protocol and registered to the container in Vapor 3 can be now be expressed as extensions to either Application or Request.

```diff
struct MyAPI {
    let client: Client
    func foo() { ... }
}
- extension MyAPI: Service { }
- services.register { container -> MyAPI in
-     return try MyAPI(client: container.make())
- }
+ extension Request {
+     var myAPI: MyAPI { 
+         .init(client: self.client)
+     }
+ }
```

This service can then be accessed using the extension instead of `make`.

```diff
- try req.make(MyAPI.self).foo()
+ req.myAPI.foo()
```

### Custom Providers

Most custom services can be implemented using extensions as shown in the previous section. However, some advanced providers may need to hook into the application lifecycle or use stored properties.

Application's new `Lifecycle` helper can be used to register lifecycle handlers.

```swift
struct PrintHello: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        print("Hello!")
    }
}

app.lifecycle.use(PrintHello())
```

To store values on Application, you case use the new `Storage` helper. 

```swift
struct MyNumber: StorageKey {
    typealias Value = Int
}
app.storage[MyNumber.self] = 5
print(app.storage[MyNumber.self]) // 5
```

Accessing `app.storage` can be wrapped in a settable computed property to create a concise API.

```swift
extension Application {
    var myNumber: Int? {
        get { self.storage[MyNumber.self] }
        set { self.storage[MyNumber.self] = newValue }
    }
}

app.myNumber = 42
print(app.myNumber) // 42
```

## NIO

Vapor 4 now exposes SwiftNIO's async APIs directly and does not attempt to overload methods like `map` and `flatMap` or alias types like `EventLoopFuture`. Vapor 3 provided overloads and aliases for backward compatibility with early beta versions that were released before SwiftNIO existed. These have been removed to reduce confusion with other SwiftNIO compatible packages and better follow SwiftNIO's best practice recommendations. 

### Async naming changes

The most obvious change is that the `Future` typealias for `EventLoopFuture` has been removed. This can be fixed fairly easily with a find and replace.

Furthermore, NIO does not support the `to:` labels that Vapor 3 added. Given Swift 5.2's improved type inference, `to:` is less necessary now anyway.

```diff
- futureA.map(to: String.self) { ... }
+ futureA.map { ... }
``` 

Methods prefixed with `new`, like `newPromise` have been changed to `make` to better suit Swift style.

```diff
- let promise = eventLoop.newPromise(String.self)
+ let promise = eventLoop.makePromise(of: String.self)
```

`catchMap` is no longer available, but NIO's methods like `mapError` and `flatMapErrorThrowing` will work instead. 

Vapor 3's global `flatMap` method for combining multiple futures is no longer available. This can be replaced by using NIO's `and` method to combine many futures together. 

```diff
- flatMap(futureA, futureB) { a, b in 
+ futureA.and(futureB).flatMap { (a, b) in
    // Do something with a and b.
}
```

### ByteBuffer

Many methods and properties that previously used `Data` now use NIO's `ByteBuffer`. This type is a more powerful and performant byte storage type. You can read more about its API in [SwiftNIO's ByteBuffer docs](https://apple.github.io/swift-nio/docs/current/NIOCore/Structs/ByteBuffer.html).

To convert a `ByteBuffer` back to `Data`, use:

```swift
Data(buffer.readableBytesView)
```

### Throwing map / flatMap

The most difficult change is that `map` and `flatMap` can no longer throw. `map` has a throwing version named (somewhat confusingly) `flatMapThrowing`. `flatMap` however has no throwing counterpart. This may require you to restructure some asynchronous code. 

Maps that do _not_ throw should continue to work fine.

```swift
// Non-throwing map.
futureA.map { a in
    return b
}
```

Maps that _do_ throw must be renamed to `flatMapThrowing`. 

```diff
- futureA.map { a in
+ futureA.flatMapThrowing { a in
    if ... {
        throw SomeError()
    } else {
        return b
    }
}
```

Flat-maps that do _not_ throw should continue to work fine.

```swift
// Non-throwing flatMap.
futureA.flatMap { a in
    return futureB
}
```

Instead of throwing an error inside a flat-map, return a future error. If the error originates from another throwing method, the error can be caught in a do / catch and returned as a future.

```swift
// Returning a caught error as a future.
futureA.flatMap { a in
    do {
        try doSomething()
        return futureB
    } catch {
        return eventLoop.makeFailedFuture(error)
    }
}
```

Throwing method calls can also be refactored into a `flatMapThrowing` and chained using tuples.

```swift
// Refactored throwing method into flatMapThrowing with tuple-chaining.
futureA.flatMapThrowing { a in
    try (a, doSomeThing())
}.flatMap { (a, result) in
    // result is the value of doSomething.
    return futureB
}
```

## Routing

Routes are now registered directly to Application. 

```swift
app.get("hello") { req in
    return "Hello, world"
}
```

This means you no longer need to register a router to services. Simply pass the application to your `routes` method and start adding routes. All of the methods available on `RoutesBuilder` are available on `Application`. 

### Synchronous Content

Decoding request content is now synchronous.

```swift
let payload = try req.content.decode(MyPayload.self)
print(payload) // MyPayload
```

This behavior can be overridden by register routes using the `.stream` body collection strategy. 

```swift
app.on(.POST, "streaming", body: .stream) { req in
    // Request body is now asynchronous.
    req.body.collect().map { buffer in
        HTTPStatus.ok
    }
}
```

### Comma-separated paths

Paths must now be comma separated and not contain `/` for consistency. 

```diff
- router.get("v1/users/", "posts", "/comments") { req in 
+ app.get("v1", "users", "posts", "comments") { req in
    // Handle request.
}
```

### Route parameters

The `Parameter` protocol has been removed in favor of explicitly named parameters. This prevents issues with duplicate parameters and un-ordered fetching of parameters in middleware and route handlers.

```diff
- router.get("planets", String.parameter) { req in 
-     let id = req.parameters.next(String.self)
+ app.get("planets", ":id") { req in
+     let id = req.parameters.get("id")
      return "Planet id: \(id)"
  }
```

Route parameter usage with models is mentioned in the Fluent section.

## Middleware

`MiddlewareConfig` has been renamed to `MiddlewareConfiguration` and is now a property on Application. You can add middleware to your app using `app.middleware`. 

```diff
let corsMiddleware = CORSMiddleware(configuration: ...)
- var middleware = MiddlewareConfig()
- middleware.use(corsMiddleware)
+ app.middleware.use(corsMiddleware)
- services.register(middlewares)
```

Middleware can no longer be registered by type name. Initialize the middleware first before registering.

```diff
- middleware.use(ErrorMiddleware.self)
+ app.middleware.use(ErrorMiddleware.default(environment: app.environment))
```

To remove all default middleware, set `app.middleware` to an empty config using:

```swift
app.middleware = .init()
```

## Fluent

Fluent's API is now database agnostic. You can import just `Fluent`.

```diff
- import FluentMySQL
+ import Fluent
```

### Models

All models now use the `Model` protocol and must be classes.

```diff
- struct Planet: MySQLModel {
+ final class Planet: Model {
```

All fields are declared using `@Field` or `@OptionalField` property wrappers. 

```diff
+ @Field(key: "name")
var name: String

+ @OptionalField(key: "age")
var age: Int?
```

A model's ID must be defined using the `@ID` property wrapper.

```diff
+ @ID(key: .id)
var id: UUID?
```

Models using an identifier with a custom key or type must use `@ID(custom:)`.

All models must have their table or collection name defined statically.

```diff
final class Planet: Model {
+   static let schema = "Planet"    
}
```

All models must now have an empty initializer. Since all properties use property wrappers, this can be empty.

```diff
final class Planet: Model {
+   init() { }
}
```

Model's `save`, `update`, and `create` no longer return the model instance.

```diff
- model.save(on: ...)
+ model.save(on: ...).map { model }
```

Models can no longer be used as route path components. Use `find` and `req.parameters.get` instead.

```diff
- try req.parameters.next(ServerSize.self)
+ ServerSize.find(req.parameters.get("size"), on: req.db)
+     .unwrap(or: Abort(.notFound))
```

`Model.ID` has been renamed to `Model.IDValue`. 

Model timestamps are now declared using the `@Timestamp` property wrapper.

```diff
- static var createdAtKey: TimestampKey? = \.createdAt
+ @Timestamp(key: "createdAt", on: .create)
var createdAt: Date?
```

### Relations

Relations are now defined using property wrappers.

Parent relations use the `@Parent` property wrapper and contain the field property internally. The key passed to `@Parent` should be the name of the field storing the identifier in the database.

```diff
- var serverID: Int
- var server: Parent<App, Server> { 
-    parent(\.serverID) 
- }
+ @Parent(key: "serverID") 
+ var server: Server
```

Children relations use the `@Children` property wrapper with a key path to the related `@Parent`.

```diff
- var apps: Children<Server, App> { 
-     children(\.serverID) 
- }
+ @Children(for: \.$server) 
+ var apps: [App]
```

Siblings relations use the `@Siblings` property wrapper with key paths to the pivot model.

```diff
- var users: Siblings<Company, User, Permission> {
-     siblings()
- }
+ @Siblings(through: Permission.self, from: \.$user, to: \.$company) 
+ var companies: [Company]
```

Pivots are now normal models that conform to `Model` with two `@Parent` relations and zero or more additional fields.

### Query

The database context is now accessed via `req.db` in route handlers.

```diff
- Planet.query(on: req)
+ Planet.query(on: req.db)
```

`DatabaseConnectable` has been renamed to `Database`.

Key paths to fields are now prefixed with `$` to specify the property wrapper instead of the field value.

```diff
- filter(\.foo == ...) 
+ filter(\.$foo == ...)
```

### Migrations

Models no longer support reflection-based auto migrations. All migrations must be written manually. 

```diff
- extension Planet: Migration { }
+ struct CreatePlanet: Migration {
+     ...
+}
```

Migrations are now stringly typed and decoupled from models and use the `Migration` protocol. 

```diff
- struct CreateGalaxy: <#Database#>Migration {
+ struct CreateGalaxy: Migration {
```

The `prepare` and `revert` methods are no longer static.

```diff
- static func prepare(on conn: <#Database#>Connection) -> Future<Void> {
+ func prepare(on database: Database) -> EventLoopFuture<Void> 
```

Creating a schema builder is done via an instance method on `Database`.

```diff
- <#Database#>Database.create(Galaxy.self, on: conn) { builder in
-    // Use builder.
- }
+ var builder = database.schema("Galaxy")
+ // Use builder.
```

The `create`, `update`, and `delete` methods are now called on the schema builder similar to how query builder works.

Fields definitions are now stringly typed and follow the pattern:

```swift
field(<name>, <type>, <constraints>)
```

See the example below.

```diff
- builder.field(for: \.name)
+ builder.field("name", .string, .required)
```

Schema building can now be chained like query builder.

```swift
database.schema("Galaxy")
    .id()
    .field("name", .string, .required)
    .create()
```

### Fluent Configuration

`DatabasesConfig` has been replaced by `app.databases`.

```swift
try app.databases.use(.postgres(url: "postgres://..."), as: .psql)
```

`MigrationsConfig` has  been replaced by `app.migrations`.

```swift
app.migrations.use(CreatePlanet(), on: .psql)
```

### Repositories

As the way services work in Vapor 4 has changed, that also means that the way to do database repositories has changed. You still need a protocol such as `UserRepository` but instead of making a `final class` conform to that protocol, you should make a `struct` instead.

```diff
- final class DatabaseUserRepository: UserRepository {
+ struct DatabaseUserRepository: UserRepository {
      let database: Database
      func all() -> EventLoopFuture<[User]> {
          return User.query(on: database).all()
      }
  }
```

You should also remove conformance from `ServiceType` as this no longer exists in Vapor 4. 
```diff
- extension DatabaseUserRepository {
-     static let serviceSupports: [Any.Type] = [Athlete.self]
-     static func makeService(for worker: Container) throws -> Self {
-         return .init()
-     }
- }
```

Instead you should create a `UserRepositoryFactory`:
```swift
struct UserRepositoryFactory {
    var make: ((Request) -> UserRepository)?
    mutating func use(_ make: @escaping ((Request) -> UserRepository)) {
        self.make = make
    }
}
```
This factory is responsible for returning a `UserRepository` for a `Request`.

Next step is to add an extension to `Application` to specify your factory:
```swift
extension Application {
    private struct UserRepositoryKey: StorageKey { 
        typealias Value = UserRepositoryFactory 
    }

    var users: UserRepositoryFactory {
        get {
            self.storage[UserRepositoryKey.self] ?? .init()
        }
        set {
            self.storage[UserRepositoryKey.self] = newValue
        }
    }
}
```

To use the actual repository inside of a `Request` add this extension to `Request`:
```swift
extension Request {
    var users: UserRepository {
        self.application.users.make!(self)
    }
}
```

Last step is to specify the factory inside `configure.swift`
```swift
app.users.use { req in
    DatabaseUserRepository(database: req.db)
}
```

You can now access your repository in your route handlers with: `req.users.all()` and easily replace the factory inside tests.
If you want to use a mocked repository inside tests, first create a `TestUserRepository`
```swift
final class TestUserRepository: UserRepository {
    var users: [User]
    let eventLoop: EventLoop

    init(users: [User] = [], eventLoop: EventLoop) {
        self.users = users
        self.eventLoop = eventLoop
    }

    func all() -> EventLoopFuture<[User]> {
        eventLoop.makeSuccededFuture(self.users)
    }
}
```

You can now use this mocked repository inside your tests as follows:
```swift
final class MyTests: XCTestCase {
    func test() throws {
        let users: [User] = []
        app.users.use { TestUserRepository(users: users, eventLoop: $0.eventLoop) }
        ...
    }
}
```
