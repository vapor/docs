# Vapor Style Guide

## Motivation

The Vapor style guide is a perspective on how to write Vapor application code that is clean, readable, and maintainable. It can serve as a jumping off point within your organization (or yourself) for how to write code in a style that aligns with the Vapor ecosystem. We think this guide can help solidify common ideas that occur across most applications and will be a reference for maintainers when starting a new project. This style guide is opinionated, so you should adapt your code in places where you don’t agree.

## Contributing

To contribute to this guide, please submit a pull request that includes your proposed changes as well as logic to support your addition or modification. Pull requests will be reviewed by the maintainers and the rationale behind the maintainers’ decision to accept or deny the changes will be posted in the pull request.

## Application Structure

The structure of your Vapor application is important from a readability standpoint, but also in terms of functionality. Application structure refers to a few different aspects of the Vapor ecosystem, but in particular, it is the way in which you structure your file, folders, and assets.

The preferred way to structure your application is by separating the application into a few main parts:

- Controllers
- Middleware
- Models
- Setup
- Utilities
- Services

The structure ensures that new members working on your project can easily find the file or asset they are looking for.

#### Controllers Folder

The controllers folder houses all of the controllers for your application which correspond to your routes. If you are building an application that serves both API responses and frontend responses, this folder should be further segmented into an `API Controllers` folder and a `View Controllers` folder.

#### Middleware Folder

The middleware folder contains any custom middleware that you’ve written for your application. Each piece of middleware should be descriptively named and should only be responsible for one piece of functionality.

#### Models Folder

“Models” in this document means an object that can be used to store or return data throughout the application. Models are not specific to Fluent - Entities, however, include database information that make it possible to persist and query them.

The Models folder should be broken down into four parts: Entities, Requests, Responses, and View Contexts (if applicable to your application). The `Requests` and `Responses` folder hold object files that are used to decode requests or encode responses. For more information on this, see the “File Naming” section.

If your application handles view rendering via Leaf, you should also have a folder that holds all of your view contexts. These contexts are the same type of objects as the Request and Response objects, but are specifically for passing data to the view layer.

The Entities folder is further broken up into a folder for each database model that exists within your application. For example, if you have a `User` model that represents a `users` table, you would have a `Users` folder that contains `User.swift` (the Fluent model representation) and then any other applicable files for this entity. Other common files found at this level include files to extend functionality of the object, repository protocols/implementations, and data transformation extensions.

#### Setup Folder

The setup folder has all of the necessary pieces that are called on application setup. This includes `app.swift`, `boot.swift`, `configure.swift`, `migrate.swift`, and `routes.swift`. For information on each of these files, see the “Configuration” section.

#### Utilities Folder

The utilities folder serves as a general purpose location for any objects or helpers that don’t fit the other folders. For example, in your quest to eliminate stringly-typed code (see the “General Advice” section) you might place a `Constants.swift` file in this location.

#### Services Folder
The services folder is used to hold any custom services that are created and registered. 

The final application structure (inside the Sources folder) looks like this:

```
├── Controllers
│   ├── API\ Controllers
│   └── View\ Controllers
├── Middleware
├── Models
│   ├── Entities
│   │   └── User
│   ├── Requests
│   └── Responses
│   └── View\ Contexts
├── Setup
│   ├── app.swift
│   ├── boot.swift
│   ├── commands.swift
│   ├── configure.swift
│   ├── content.swift
│   ├── databases.swift
│   ├── middlewares.swift
│   ├── migrate.swift
│   ├── repositories.swift
│   └── routes.swift
├── Utilities
├── Services
```

## Configuration

Configuring your application correctly is one of the most important parts of a successful Vapor application. The main function of the configuring a Vapor application is correctly registering all of your services and 3rd party providers.

**Note**: For more information on registering credentials and secrets, see the “Credentials” section.

#### Files

Depending on your application you should have some or all of the following files:

- app.swift (use the default template version)
- boot.swift (use the default template version)
- commands.swift (Optional)
- configure.swift
- content.swift
- databases.swift (Optional)
- middlewares.swift
- migrate.swift (Optional)
- repositories.swift (Optional)
- routes.swift

#### configure.swift

Use this file to register your services, providers, and any other code that needs to run as part of the Vapor application setup process.

We recommend registering all services (with some exceptions, like `BlockingIOThreadPool`, that have internal synchronization code) using the closure method. The closure gets called each time a container requests that service. There's one container per thread, meaning that you get one service per thread. As a result, you don't need to think about synchronizing access and state in the object, which is otherwise difficult. The tradeoff to this method is memory usage, which is typically negligible for a small class, but you gain performance.

#### routes.swift

The routes.swift file is used to declare route registration for your application. Typically, the routes.swift file looks like this:

```swift
import Vapor

public func routes(_ router: Router, _ container: Container) throws {
    try router.register(collection: MyControllerHere(db: container.connectionPool(to: .mysql)))
}
```

You should call this function from `configure.swift` like this:

```swift
    services.register(Router.self) { container -> EngineRouter in
        let router = EngineRouter.default()
        try routes(router, container)
        return router
    }
```

For more information on routes, see the “Routes and Controllers” section.

#### commands.swift

Use this file to add your custom commands to your application. For example:

```swift
import Vapor

public func commands(config: inout CommandConfig) {
    config.useFluentCommands()

    config.use(MyCustomCommand(), as: "my-custom-command")
    ...
}
```

You should call this function from `configure.swift` like this:

```swift
    /// Command Config
    var commandsConfig = CommandConfig.default()
    commands(config: &commandsConfig)
    services.register(commandsConfig)
```

> If your app doesn't use custom `Command`s you can omit this file.

#### content.swift

In this file you can customize the content encoding/decoding configuration for your data models. For example:

```swift
import Vapor

public func content(config: inout ContentConfig) throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    encoder.dateEncodingStrategy = .millisecondsSince1970
    decoder.dateDecodingStrategy = .millisecondsSince1970

    config.use(encoder: encoder, for: .json)
    config.use(decoder: decoder, for: .json)
}
```

You should call this function from `configure.swift` like this:

```swift
    /// Register Content Config
    var contentConfig = ContentConfig.default()
    try content(config: &contentConfig)
    services.register(contentConfig)
```

> If you don't customize the content configuration you can omit this file.

#### databases.swift

Use this file to add the databases used in your application. Extracting this logic to a separate file keeps the configure.swift code clean, as it can often get quite long. This file should look something like this:

```swift
import Vapor
import FluentMySQL //use your database driver here

public func databases(config: inout DatabasesConfig) throws {
    guard let databaseUrl = Environment.get("DATABASE_URL") else {
        throw Abort(.internalServerError)
    }

    guard let dbConfig = MySQLDatabaseConfig(url: databaseUrl) else { throw Abort(.internalServerError) }

    /// Register the databases
    config.add(database: MySQLDatabase(config: dbConfig), as: .mysql)

    ...
}
```

And then call this function from `configure.swift` like this:

```swift
    /// Register the configured SQLite database to the database config.
    var databasesConfig = DatabasesConfig()
    try databases(config: &databasesConfig)
    services.register(databasesConfig)
```

> If your app doesn't use `Fluent` you can omit this file.

#### middlewares.swift

In this file you can customize the middlewares of your application. For example:

```swift
import Vapor

public func middlewares(config: inout MiddlewareConfig) throws {
    // config.use(FileMiddleware.self) // Serves files from `Public/` directory
    config.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    // Other Middlewares...
}
```

You should call this function from `configure.swift` like this:

```swift
    /// Register middlewares
    var middlewaresConfig = MiddlewareConfig()
    try middlewares(config: &middlewaresConfig)
    services.register(middlewaresConfig)
```

#### migrate.swift

Use this file to add the migrations to your database. Extracting this logic to a separate file keeps the configure.swift code clean, as it can often get quite long. This file should look something like this:

```swift
import Vapor
import FluentMySQL //use your database driver here

public func migrate(migrations: inout MigrationConfig) throws {
    migrations.add(model: User.self, database: .mysql) //update this with your database driver
}
```

And then call this function from `configure.swift` like this:

```swift
    services.register { container -> MigrationConfig in
        var migrationConfig = MigrationConfig()
        try migrate(migrations: &migrationConfig)
        return migrationConfig
    }
```

As you continue to add models to your application, make sure that you add them to the migration file as well.

> If your app doesn't use `Fluent` you can omit this file.

#### repositories.swift

The `repositories.swift` file is responsible for registering each repository during the configuration stage. This file should look like this:

```swift
import Vapor

public func setupRepositories(services: inout Services, config: inout Config) {
    services.register(MySQLUserRepository.self)
    preferDatabaseRepositories(config: &config)
}

private func preferDatabaseRepositories(config: inout Config) {
    config.prefer(MySQLUserRepository.self, for: UserRepository.self)
}
```

Call this function from `configure.swift` like this:

```swift
setupRepositories(services: &services, config: &config)
```

For more information on the repository pattern, see the “Architecture” section.

> If your app doesn't use `Fluent` you can omit this file.

## Credentials

Credentials are a crucial part to any production-ready application. The preferred way to manage secrets in a Vapor application is via environment variables. These variables can be set via the Xcode scheme editor for testing, the shell, or in the GUI of your hosting provider.

**Credentials should never, under any circumstances, be checked into a source control repository.**

Assuming we have the following credential storage service:

```swift
import Vapor
struct APIKeyStorage: Service {
    let apiKey: String
}
```

**Bad:**

```swift
services.register { container -> APIKeyStorage in
    return APIKeyStorage(apiKey: "MY-SUPER-SECRET-API-KEY")
}
```

**Good:**

```swift
guard let apiKey = Environment.get("api-key") else { throw Abort(.internalServerError) }
services.register { container -> APIKeyStorage in
    return APIKeyStorage(apiKey: apiKey)
}
```

## File Naming

As the old saying goes, “the two hardest problems in computer science are naming things, cache invalidation, and off by one errors.” To minimize confusion and help increase readability, files should be named succinctly and descriptively.

Files that contain objects used to decode body content from a request should be appended with `Request`. For example, `LoginRequest`. Files that contain objects used to encode body content to a response should be appended with `Response`. For example, `LoginResponse`.

Controllers should also be named descriptively for their purpose. If your application contains logic for frontend responses and API responses, each controller’s name should denote their responsibility. For example, `LoginViewController` and `LoginController`. If you combine the login functionality into one controller, opt for the more generic name: `LoginController`.

## Architecture

One of the most important decisions to make up front about your app is the style of architecture it will follow. It is incredibly time consuming and expensive to retroactively change your architecture. We recommend that production-level Vapor applications use the repository pattern.

The basic idea behind the repository pattern is that it creates another abstraction between Fluent and your application code. Instead of using Fluent queries directly in controllers, this pattern encourages abstracting those queries into a more generic protocol and using that instead.

There are a few benefits to this method. First, it makes testing a lot easier. This is because during the test environment you can easily utilize Vapor’s configuration abilities to swap out which implementation of the repository protocol gets used. This makes unit testing much faster because the unit tests can use a memory version of the protocol rather than the database. The other large benefit to this pattern is that it makes it really easy to switch out the database layer if needed. Because all of the ORM logic is abstracted to this piece of the application (and the controllers don’t know it exists) you could realistically swap out Fluent with a different ORM with minimal changes to your actual application/business logic code.

Here’s an example of a `UserRepository`:

```swift
import Vapor
import FluentMySQL
import Foundation

protocol UserRepository: ServiceType {
    func find(id: Int) -> Future<User?>
    func all() -> Future<[User]>
    func find(email: String) -> Future<User?>
    func findCount(email: String) -> Future<Int>
    func save(user: User) -> Future<User>
}

final class MySQLUserRepository: UserRepository {
    let db: MySQLDatabase.ConnectionPool
    
    init(_ db: MySQLDatabase.ConnectionPool) {
        self.db = db
    }

    func find(id: Int) -> EventLoopFuture<User?> {
        return db.withConnection { conn in 
            return User.find(id, on: conn)
        }
    }

    func all() -> EventLoopFuture<[User]> {
        return db.withConnection { conn in
            return User.query(on: conn).all()
        }
    }

    func find(email: String) -> EventLoopFuture<User?> {
        return db.withConnection { conn in
            return User.query(on: conn).filter(\.email == email).first()
        }
    }

    func findCount(email: String) -> EventLoopFuture<Int> {
        return db.withConnection { conn in
            return User.query(on: conn).filter(\.email == email).count()
        }
    }

    func save(user: User) -> EventLoopFuture<User> {
        return db.withConnection { conn in
            return user.save(on: conn)
        }
    }
}

//MARK: - ServiceType conformance
extension MySQLUserRepository {
    static let serviceSupports: [Any.Type] = [UserRepository.self]

    static func makeService(for worker: Container) throws -> Self {
        return .init(try worker.connectionPool(to: .mysql))
    }
}

extension Database {
    public typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<Self>>
}
```

Then, in the controller:

```swift
let repository = try req.make(UserRepository.self)
let userQuery = repository
            .find(email: content.email)
            .unwrap(or: Abort(.unauthorized, reason: "Invalid Credentials"))
```

In this example, the controller has no idea where the data is coming from, it only knows that it exists. This model has proven to be incredibly effective with Vapor and it is our recommended architecture.

## Entities

Oftentimes entities that come from the database layer need to be transformed to make them appropriate for a JSON response or for sending to the view layer. Sometimes these data transformations require database queries as well. If the transformation is simple, use a property and not a function.

**Bad:**

```swift
func publicUser() -> PublicUser {
    return PublicUser(user: self)
}
```

**Good:**

```swift
var `public`: PublicUser {
    return PublicUser(user: self)
}
```

Transformations that require more complex processing (fetching siblings and add them to the object) should be functions that accept a DatabaseConnectable object:

```swift
func userWithSiblings(on connectable: DatabaseConnectable) throws -> Future<FullUser> {
     //do the processing here
}
```

<hr/>

We also recommend documenting all functions that exist on entities.

Unless your entity needs to be database-generic, always conform the model to the most specific model type.

**Bad:**

```swift
extension User: Model { }
```

**Good:**

```swift
extension User: MySQLModel { }
```

<hr/>

Extending the model with other conformances (Migration, Parameter, etc) should be done at the file scope via an extension.

**Bad:**

```swift
public final class User: Model, Parameter, Content, Migration {
    //..
}
```

**Good:**

```swift
public final class User {
   //..
}

extension User: MySQLModel { }
extension User: Parameter { }
extension User: Migration { }
extension User: Content { }
```

<hr/>

Property naming styles should remain consistent throughout all models.

**Bad:**

```swift
public final class User {
    var id: Int?
    var firstName: String
    var last_name: String
}
```

**Good:**

```swift
public final class User {
    var id: Int?
    var firstName: String
    var lastName: String
}
```

As a general rule, try to abstract logic into functions on the models to keep the controllers clean.

## Routes and Controllers

We suggest combining your routes into your controller to keep everything central. Controllers serve as a jumping off point for executing logic from other places, namely repositories and model functions.

Routes should be separated into functions in the controller that take a `Request` parameter and return a `ResponseEncodable` type.

**Bad:**

```swift
final class LoginViewController: RouteCollection {
    func boot(router: Router) throws {
        router.get("/login") { (req) -> ResponseEncodable in
            return ""
        }
    }
}
```

**Good:**

```swift
final class LoginViewController: RouteCollection {
    func boot(router: Router) throws {
        router.get("/login", use: login)
    }

    func login(req: Request) throws -> String {
        return ""
    }
}
```

<hr/>

When creating these route functions, the return type should always be as specific as possible.

**Bad:**

```swift
func login(req: Request) throws -> ResponseEncodable {
    return "string"
}
```

**Good:**

```swift
func login(req: Request) throws -> String {
    return "string"
}
```

<hr/>

When creating a path like `/user/:userId`, always use the most specific `Parameter` instance available.

**Bad:**

```swift
router.get("/user", Int.parameter, use: user)
```

**Good:**

```swift
router.get("/user", User.parameter, use: user)
```

<hr/>

When decoding a request, opt to decode the `Content` object when registering the route instead of in the route.

**Bad:**

```swift
router.post("/update", use: update)

func update(req: Request) throws -> Future<User> {
    return req.content.decode(User.self).map { user in
        //do something with user

        return user
    }
}
```

**Good:**

```swift
router.post(User.self, at: "/update", use: update)

func update(req: Request, content: User) throws -> Future<User> {
    return content.save(on: req)
}
```

Controllers should follow the thread-safe architecture when possible. This means passing necessary `Service`s to the controller on initialization instead of making them in the routes. 

**Bad:**

```swift
final class LoginViewController: RouteCollection {
    func boot(router: Router) throws {
        router.get("/login", use: login)
    }

    func login(req: Request) throws -> String {
        let userRepository = try req.make(UserRepository.self)
        //do something with it 

        return ""
    }
}
```

**Good:**

```swift
final class LoginViewController: RouteCollection {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func boot(router: Router) throws {
        router.get("/login", use: login)
    }

    func login(req: Request) throws -> String {
        //use `self.userRepository`
        
        return ""
    }
}
```

Controllers should only cover one idea/feature at a time. If a feature grows to encapsulate a large amount of functionality, routes should be split up into multiple controllers and organized under one common feature folder in the `Controllers` folder. For example, an app that handles generating a lot of analytical/reporting views should break up the logic by specific report to avoid cluttering a generic `ReportsViewController.swift`

## Async

Where possible, avoid specifying the type information in flatMap and map calls.

**Bad:**

```swift
let stringFuture: Future<String>
return stringFuture.map(to: Response.self) { string in
    return req.redirect(to: string)
}
```

**Good:**

```swift
let stringFuture: Future<String>
return stringFuture.map { string in
    return req.redirect(to: string)
}
```

<hr/>

When returning two objects from a chain to the next chain, use the `and(result: )` function to automatically create a tuple instead of manually creating it (the Swift compiler will most likely require return type information in this case)

**Bad:**

```swift
let stringFuture: Future<String>
return stringFuture.flatMap(to: (String, String).self) { original in
    let otherStringFuture: Future<String>

    return otherStringFuture.map { other in
        return (other, original)
    }
}.map { other, original in
    //do something
}
```

**Good:**

```swift
let stringFuture: Future<String>
return stringFuture.flatMap(to: (String, String).self) { original in
    let otherStringFuture: Future<String>
    return otherStringFuture.and(result: original)
}.map { other, original in
    //do something
}
```

<hr/>

When returning more than two objects from one chain to the next, do not rely on the `and(result )` method as it can only create, at most, a two object tuple. Use a nested `map` instead.

**Bad:**

```swift
let stringFuture: Future<String>
let secondFuture: Future<String>

return flatMap(to: (String, (String, String)).self, stringFuture, secondFuture) { first, second in
    let thirdFuture: Future<String>
    return thirdFuture.and(result: (first, second))
}.map { other, firstSecondTuple in
    let first = firstSecondTuple.0
    let second = firstSecondTuple.1
    //do something
}
```

**Good:**

```swift
let stringFuture: Future<String>
let secondFuture: Future<String>

return flatMap(to: (String, String, String).self, stringFuture, secondFuture) { first, second in
    let thirdFuture: Future<String>
    return thirdFuture.map { third in
        return (first, second, third)
    }
}.map { first, second, third in
    //do something
}
```

<hr/>

Always use the global `flatMap` and `map` methods to execute futures concurrently when the functions don’t need to wait on each other.

**Bad:**

```swift
let stringFuture: Future<String>
let secondFuture: Future<String>

return stringFuture.flatMap { string in
    print(string)
    return secondFuture
}.map { second in
    print(second)
    //finish chain
}
```

**Good:**

```swift
let stringFuture: Future<String>
let secondFuture: Future<String>

return flatMap(to: Void.self, stringFuture, secondFuture) { first, second in
    print(first)
    print(second)

    return .done(on: req)
}
```

<hr/>

Avoid nesting async functions more than once per chain, as it becomes unreadable and unsustainable.

**Bad:**

```swift
let stringFuture: Future<String>

return stringFuture.flatMap { first in
    let secondStringFuture: Future<String>

    return secondStringFuture.flatMap { second in
        let thirdStringFuture: Future<String>

        return thirdStringFuture.flatMap { third in
            print(first)
            print(second)
            print(third)

            return .done(on: req)
        }
    }
}
```

**Good:**

```swift
let stringFuture: Future<String>

return stringFuture.flatMap(to: (String, String).self) { first in
    let secondStringFuture: Future<String>
    return secondStringFuture.and(result: first)
}.flatMap { second, first in
    let thirdStringFuture: Future<String>

    //it's ok to nest once
    return thirdStringFuture.flatMap { third in
        print(first)
        print(second)
        print(third)

        return .done(on: req)
    }
}
```

<hr/>

Use `transform(to: )` to avoid chaining an extra, unnecessary level.

**Bad:**

```swift
let stringFuture: Future<String>

return stringFuture.map { _ in
    return .ok
}
```

**Good:**

```swift
let stringFuture: Future<String>
return stringFuture.transform(to: .ok)
```

## Testing

Testing is a crucial part of Vapor applications that helps ensure feature parity across versions. We strongly recommend testing for all Vapor applications.

While testing routes, avoid changing behavior only to accommodate for the testing environment. Instead, if there is functionality that should differ based on the environment, you should create a service and swap out the selected version during the testing configuration.

**Bad:**

```swift
func login(req: Request) throws -> Future<View> {
    if req.environment != .testing {
        try req.verifyCSRF()
    }

    //rest of the route
}
```

**Good:**

```swift
func login(req: Request) throws -> Future<View> {
    let csrf = try req.make(CSRF.self)
    try csrf.verify(req: req)
    //rest of the route
}
```

Note how the correct way of handling this situation includes making a service - this is so that you can mock out fake functionality in the testing version of the service.

Every test should setup and teardown your database. **Do not** try and persist state between tests.

Tests should be separated into unit tests and integration. If using the repository pattern, the unit tests should use the memory version of the repositories while the integration tests should use the database version of the repositories.

## Fluent

ORMs are notorious for making it really easy to write bad code that works but is terribly inefficient or incorrect. Fluent tends to minimize this possibility thanks to the usage of features like KeyPaths and strongly-typed decoding, but there are still a few things to watch out for.

Actively watch out for and avoid code that produces N+1 queries. Queries that have to be run for every instance of a model are bad and typically produce N+1 problems. Another identifying feature of N+1 code is the combination of a loop (or `map`) with `flatten`.

**Bad:**

```swift
//assume this is filled and that each owner can have one pet
let owners = [Owner]()
var petFutures = [Future<Pet>]()

for owner in owners {
    let petFuture = try Pet.find(owner.petId, on: req).unwrap(or: Abort(.badRequest))
    petFutures.append(petFuture)
}

let allPets = petFutures.flatten(on: req)
```

**Good:**

```swift
//assume this is filled and that each owner can have one pet
let owners = [Owner]()
let petIds = owners.compactMap { $0.petId }
let allPets = try Pet.query(on: req).filter(\.id ~~ petIds).all()
```

Notice the use of the `~~` infix operator which creates an `IN` SQL query.

<hr/>

In addition to reducing Fluent inefficiencies, opt for using native Fluent queries over raw queries unless your intended query is too complex to be created using Fluent.

**Bad:**

```swift
conn.raw("SELECT * FROM users;")
```

**Good:**

```swift
User.query(on: req).all()
```

## Leaf

Creating clean, readable Leaf files is important. One of the ways to go about doing this is through the use of base templates. Base templates allow you to specify only the different part of the page in the main leaf file for that view, and then base template will sub in the common components of the page (meta headers, the page footer, etc). For example:

`base.leaf`

```html
<!DOCTYPE html> <!-- HTML5 -->
<html lang="en">
    <head>
        <!-- Basic Meta -->
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="x-ua-compatible" content="ie=edge">

        <title>#get(title)</title>
    </head>
    <body>
        #get(body)
        #embed("Views/footer")
    </body>
</html>
```

Notice the calls to `#get` and `#embed` which piece together the supplied variables from the view and create the final HTML page.

`login.leaf`

```html
#set("title") { Login }

#set("body") {
    <p>Add your login page here</p>
}

#embed("Views/base")
```

In addition to extracting base components to one file, you should also extract common components to their own file. For example, instead of repeating the snippet to create a bar graph, put it inside of a different file and then use `#embed()` to pull it into your main view.

Always use `req.view()` to render the views for your frontend. This will ensure that the views will take advantage of caching in production mode, which dramatically speeds up your frontend responses.

## Errors

Depending on the type of application you are building (frontend, API-based, or hybrid) the way that you throw and handle errors may differ. For example, in an API-based system, throwing an error generally means you want to return it as a response. However, in a frontend system, throwing an error most likely means that you will want to handle it further down the line to give the user contextual frontend information.

As a general rule of thumb, conform all of your custom error types to Debuggable. That helps `ErrorMiddleware` print better diagnostics and can lead to easier debugging.

**Bad:**

```swift
enum CustomError: Error {
    case error
}
```

**Good:**

```swift
enum CustomError: Debuggable {
    case error

    //MARK: - Debuggable
    var identifier: String {
        switch self {
        case .error: return "error"
        }
    }

    var reason: String {
        switch self {
        case .error: return "Specify reason here"
        }
    }
}
```

<hr/>

Include a `reason` when throwing generic `Abort` errors to indicate the context of the situation.

**Bad:**

```swift
throw Abort(.badRequest)
```

**Good:**

```swift
throw Abort(.badRequest, reason: "Could not get data from external API.")
```

## 3rd Party Providers 
When building third party providers for Vapor, it's important to have a certain consistency that users will be able to become familiar with when switching or adding new providers. Although Vapor is very young, there are already certain patterns that make sense when writing providers.

When creating a provider library, you should omit phrases like `Provider` or `Package`. Take the StripeProvider for example, while the name of the project itself can be named `StripeProvider` the library name should be just the product itself:
```swift
let package = Package(
    name: "StripeProvider",
    products: [
        .library(name: "Stripe", targets: ["Stripe"])
    ],
)
```
This allows for easy to read and clean import statements:
`import Stripe` rather than `import StripeProvider`.


## Overall Advice

- Use `//MARK:` to denote sections of your controllers or configuration so that it is easier for other project members to find critically important areas.
- Only import modules that are needed for that specific file. Adding extra modules creates bloat and makes it difficult to deduce that controller’s responsibility.
- Where possible, use Swift doc-blocks to document methods. This is especially important for methods implements on entities so that other project members understand how the function affects persisted data.
- Do not retrieve environment variables on a repeated basis. Instead, use a custom service and register those variables during the configuration stage of your application (see “Configuration”)
- Reuse `DateFormatters` where possible (while also maintaining thread safety). In particular, don’t create a date formatter inside of a loop as they are expensive to make.
- Store dates in a computer-readable format until the last possible moment when they must be converted to human-readable strings. That conversion is typically very expensive and is unnecessary when passing dates around internally. Offloading this responsibility to JavaScript is a great tactic as well if you are building a front-end application.
- Eliminate stringly-typed code where possible by storing frequently used strings in a file like `Constants.swift`.


## Maintainers

This style guide was written and is maintained by the following Vapor members:

- Andrew ([@andrewangeta](https://github.com/andrewangeta))
- Jimmy ([@mcdappdev](https://github.com/mcdappdev)) (Project manager)
- Jonas ([@joscdk](https://github.com/joscdk))
- Tanner ([@tanner0101](https://github.com/tanner0101))
- Tim ([@0xtim](https://github.com/0xtim))
- Gustavo ([@gperdomor](https://github.com/gperdomor))