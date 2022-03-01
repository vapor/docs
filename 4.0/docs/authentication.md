# Authentication

Authentication is the act of verifying a user's identity. This is done through the verification of credentials like a username and password or unique token. Authentication (sometimes called auth/c) is distinct from authorization (auth/z) which is the act of verifying a previously authenticated user's permissions to perform certain tasks.

## Introduction

Vapor's Authentication API provides support for authenticating a user via the `Authorization` header, using [Basic](https://tools.ietf.org/html/rfc7617) and [Bearer](https://tools.ietf.org/html/rfc6750). It also supports authenticating a user via the data decoded from the [Content](/content.md) API.

Authentication is implemented by creating an `Authenticator` which contains the verification logic. An authenticator can be used to protect individual route groups or an entire app. The following authenticator helpers ship with Vapor:

|Protocol|Description|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Base authenticator capable of creating middleware.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Authenticates Basic authorization header.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Authenticates Bearer authorization header.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|Authenticates a credentials payload from the request body.|

If authentication is successful, the authenticator adds the verified user to `req.auth`. This user can then be accessed using `req.auth.get(_:)` in routes protected by the authenticator. If authentication fails, the user is not added to `req.auth` and any attempts to access it will fail.

## Authenticatable

To use the Authentication API, you first need a user type that conforms to `Authenticatable`. This can be a `struct`, `class`, or even a Fluent `Model`. The following examples assume this simple `User` struct that has one property: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Each example below will use an instance of an authenticator which we created. In these examples, we've called it `UserAuthenticator`.

### Route

Authenticators are middleware and be be used for protecting routes.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` is used to fetch the authenticated `User`. If authentication failed, this method will throw an error, protecting the route. 

### Guard Middleware

You can also use `GuardMiddleware` in your route group to ensure that a user has been authenticated before reaching your route handler.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Requiring authentication is not done by the authenticator middleware to allow for composition of authenticators. Read more about [composition](#composition) below.

## Basic

Basic authentication sends a username and password in the `Authorization` header. The username and password are concatenated with a colon (e.g. `test:secret`), base-64 encoded, and prefixed with `"Basic "`. The following example request encodes the username `test` with password `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

Basic authentication is typically used once to log a user in and generate a token. This minimizes how frequently the user's sensitive password must be sent. You should never send Basic authorization over a plaintext or unverified TLS connection.

To implement Basic authentication in your app, create a new authenticator conforming to `BasicAuthenticator`. Below is an example authenticator hard-coded to verify the request from above.


```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

If you're using `async`/`await` you can use `AsyncBasicAuthenticator` instead:

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

This protocol requires you to implement `authenticate(basic:for:)` which will be called when an incoming request contains the `Authorization: Basic ...` header. A `BasicAuthorization` struct containing the username and password is passed to the method.

In this test authenticator, the username and password are tested against hard-coded values. In a real authenticator, you might check against a database or external API. This is why the `authenticate` method allows you to return a future. 

!!! tip
    Passwords should never be stored in a database as plaintext. Always use password hashes for comparison.

If the authentication parameters are correct, in this case matching the hard-coded values, a `User` named Vapor is logged in. If the authentication parameters do not match, no user is logged in, which signifies authentication failed. 

If you add this authenticator to your app, and test the route defined above, you should see the name `"Vapor"` returned for a successful login. If the credentials are not correct, you should see a `401 Unauthorized` error.

## Bearer

Bearer authentication sends a token in the `Authorization` header. The token is prefixed with `"Bearer "`. The following example request sends the token `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

Bearer authentication is commonly used for authentication of API endpoints. The user typically requests a Bearer token by sending credentials like a username and password to a login endpoint. This token may last minutes or days depending on the application's needs. 

As long as the token is valid, the user can use it in place of his or her credentials to authenticate against the API. If the token becomes invalid, a new one can be generated using the login endpoint.

To implement Bearer authentication in your app, create a new authenticator conforming to `BearerAuthenticator`. Below is an example authenticator hard-coded to verify the request from above.

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

If you're using `async`/`await` you can use `AsyncBearerAuthenticator` instead:

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

This protocol requires you to implement `authenticate(bearer:for:)` which will be called when an incoming request contains the `Authorization: Bearer ...` header. A `BearerAuthorization` struct containing the token is passed to the method.

In this test authenticator, the token is tested against a hard-coded value. In a real authenticator, you might verify the token by checking against a database or using cryptographic measures, like is done with JWT. This is why the `authenticate` method allows you to return a future. 

!!! tip
	When implementing token verification, it's important to consider horizontal scalability. If your application needs to handle many users concurrently, authentication can be a potential bottleneck. Consider how your design will scale across multiple instances of your application running at once.

If the authentication parameters are correct, in this case matching the hard-coded value, a `User` named Vapor is logged in. If the authentication parameters do not match, no user is logged in, which signifies authentication failed. 

If you add this authenticator to your app, and test the route defined above, you should see the name `"Vapor"` returned for a successful login. If the credentials are not correct, you should see a `401 Unauthorized` error.

## Composition

Multiple authenticators can be composed (combined together) to create more complex endpoint authentication. Since an authenticator middleware will not reject the request if authentication fails, more than one of these middleware can be chained together. Authenticators can be composed in two key ways. 

### Composing Methods


The first method of authentication composition is chaining more than one authenticator for the same user type. Take the following example:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Do something with user.
}
```

This example assumes two authenticators `UserPasswordAuthenticator` and `UserTokenAuthenticator` that both authenticate `User`. Both of these authenticators are added to the route group. Finally, `GuardMiddleware` is added after the authenticators to require that `User` was successfully authenticated. 

This composition of authenticators results in a route that can be accessed by either password or token. Such a route could allow a user to login and generate a token, then continue to use that token to generate new tokens.

### Composing Users

The second method of authentication composition is chaining authenticators for different user types. Take the following example:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Do something.
}
```

This example assumes two authenticators `AdminAuthenticator` and `UserAuthenticator` that authenticate `Admin` and `User`, respectively. Both of these authenticators are added to the route group. Instead of using `GuardMiddleware`, a check in the route handler is added to see if either `Admin` or `User` were authenticated. If not, an error is thrown.

This composition of authenticators results in a route that can be accessed by two different types of users with potentially different methods of authentication. Such a route could allow for normal user authentication while still giving access to a super-user.

## Manual

You can also handle authentication manually using `req.auth`. This is especially useful for testing.

To manually log a user in, use `req.auth.login(_:)`. Any `Authenticatable` user can be passed to this method.

```swift
req.auth.login(User(name: "Vapor"))
```

To get the authenticated user, use `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

You can also use `req.auth.get(_:)` if you don't want to automatically throw an error when authentication fails.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

To unauthenticate a user, pass the user type to `req.auth.logout(_:)`. 

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](fluent/overview.md) defines two protocols `ModelAuthenticatable` and `ModelTokenAuthenticatable` which can be added to your existing models. Conforming your models to these protocols allows for the creation of authenticators for protecting endpoints. 

`ModelTokenAuthenticatable` authenticates with a Bearer token. This is what you use to protect most of your endpoints. `ModelAuthenticatable` authenticates with username and password and is used by a single endpoint for generating tokens. 

This guide assumes you are familiar with Fluent and have successfully configured your app to use a database. If you are new to Fluent, start with the [overview](fluent/overview.md).

### User

To start, you will need a model representing the user that will be authenticated. For this guide, we'll be using the following model, but you are free to use an existing model.

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

The model must be able to store a username, in this case an email, and a password hash. We also set `email` to be a unique field, to avoid duplicate users. The corresponding migration for this example model is here:

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

Don't forget to add the migration to `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

The first thing you will need is an endpoint to create new users. Let's use `POST /users`. Create a [Content](content.md) struct representing the data this endpoint expects.

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

If you like, you can conform this struct to [Validatable](validation.md) to add validation requirements.

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

Now you can create the `POST /users` endpoint. 

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

This endpoint validates the incoming request, decodes the `User.Create` struct, and checks that the passwords match. It then uses the decoded data to create a new `User` and saves it to the database. The plaintext password is hashed using `Bcrypt` before saving to the database. 

Build and run the project, making sure to migrate the database first, then use the following request to create a new user. 

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### Model Authenticatable

Now that you have a user model and an endpoint to create new users, let's conform the model to `ModelAuthenticatable`. This will allow for the model to be authenticated using username and password.

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

This extension adds `ModelAuthenticatable` conformance to `User`. The first two properties specify which fields should be used for storing the username and password hash respectively. The `\` notation creates a key path to the fields that Fluent can use to access them.

The last requirement is a method for verifying plaintext passwords sent in the Basic authentication header. Since we're using Bcrypt to hash the password during signup, we'll use Bcrypt to verify that the supplied password matches the stored password hash.

Now that the `User` conforms to `ModelAuthenticatable`, we can create an authenticator for protecting the login route.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` adds a static method `authenticator` for creating an authenticator.

Test that this route works by sending the following request.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

This request passes the username `test@vapor.codes` and password `secret42` via the Basic authentication header. You should see the previously created user returned.

While you could theoretically use Basic authentication to protect all of your endpoints, it's recommended to use a separate token instead. This minimizes how often you must send the user's sensitive password over the Internet. It also makes authentication much faster since you only need to perform password hashing during login.

### User Token

Create a new model for representing user tokens.

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

This model must have a `value` field for storing the token's unique string. It must also have a [parent-relation](fluent/overview.md#parent) to the user model. You may add additional properties to this token as you see fit, such as an expiration date. 

Next, create a migration for this model.

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

Notice that this migration makes the `value` field unique. It also creates a foreign key reference between the `user_id` field and the users table. 

Don't forget to add the migration to `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

Finally, add a method on `User` for generating a new token. This method will be used during login.

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}
```

Here we're using `[UInt8].random(count:)` to generate a random token value. For this example, 16 bytes, or 128 bits, of random data are being used. You can adjust this number as you see fit. The random data is then base-64 encoded to make it easy to transmit in HTTP headers.

Now that you can generate user tokens, update the `POST /login` route to create and return a token.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Test that this route works by using the same login request from above. You should now get a token upon logging in that looks something like:

```
8gtg300Jwdhc/Ffw784EXA==
```

Hold onto the token you get as we'll use it shortly.

#### Model Token Authenticatable

Conform `UserToken` to `ModelTokenAuthenticatable`. This will allow for tokens to authenticate your `User` model.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        true
    }
}
```

The first protocol requirement specifies which field stores the token's unique value. This is the value that will be sent in the Bearer authentication header. The second requirement specifies the parent-relation to the `User` model. This is how Fluent will look up the authenticated user. 

The final requirement is an `isValid` boolean. If this is `false`, the token will be deleted from the database and the user will not be authenticated. For simplicity, we'll make the tokens eternal by hard-coding this to `true`.

Now that the token conforms to `ModelTokenAuthenticatable`, you can create an authenticator for protecting routes.

Create a new endpoint `GET /me` for getting the currently authenticated user.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Similar to `User`, `UserToken` now has a static `authenticator()` method that can generate an authenticator. The authenticator will attempt to find a matching `UserToken` using the value provided in the Bearer authentication header. If it finds a match, it will fetch the related `User` and authenticate it. 

Test that this route works by sending the following HTTP request where the token is the value you saved from the `POST /login` request. 

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

You should see the authenticated `User` returned. 

## Session

Vapor's [Session API](sessions.md) can be used to automatically persist user authentication between requests. This works by storing a unique identifier for the user in the request's session data after successful login. On subsequent requests, the user's identifier is fetched from the session and used to authenticate the user before calling your route handler.

Sessions are great for front-end web applications built in Vapor that serve HTML directly to web browsers. For APIs, we recommend using stateless, token-based authentication to persist user data between requests.

### Session Authenticatable

To use session-based authentication, you will need a type that conforms to `SessionAuthenticatable`. For this example, we'll use a simple struct.

```swift
import Vapor

struct User {
    var email: String
}
```

To conform to `SessionAuthenticatable`, you will need to specify a `sessionID`. This is the value that will be stored in the session data and must uniquely identify the user. 

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

For our simple `User` type, we'll use the email address as the unique session identifier.

### Session Authenticator

Next, we'll need a `SessionAuthenticator` to handle resolving instances of our User from the persisted session identifier.


```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

If you're using `async`/`await` you can use the `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Since all the information we need to initialize our example `User` is contained in the session identifier, we can create and login the user synchronously. In a real-world application, you would likely use the session identifier to perform a database lookup or API request to fetch the rest of the user data before authenticating. 

Next, let's create a simple bearer authenticator to perform the initial authentication.

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

This authenticator will authenticate a user with the email `hello@vapor.codes` when the bearer token `test` is sent.

Finally, let's combine all these pieces together in your application.

```swift
// Create protected route group which requires user auth.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Add GET /me route for reading user's email.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` is added first to enable session support on the application. More information about configuring sessions can be found in the [Session API](sessions.md) section.

Next, the `SessionAuthenticator` is added. This handles authenticating the user if a session is active. 

If the authentication has not been persisted in the session yet, the request will be forwarded to the next authenticator. `UserBearerAuthenticator` will check the bearer token and authenticate the user if it equals `"test"`.

Finally, `User.guardMiddleware()` will ensure that `User` has been authenticated by one of the previous middleware. If the user has not been authenticated, an error will be thrown. 

To test this route, first send the following request:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

This will cause `UserBearerAuthenticator` to authenticate the user. Once authenticated, `UserSessionAuthenticator` will persist the user's identifier in session storage and generate a cookie. Use the cookie from the response in a second request to the route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

This time, `UserSessionAuthenticator` will authenticate the user and you should again see the user's email returned.

### Model Session Authenticatable

Fluent models can generate `SessionAuthenticator`s by conforming to `ModelSessionAuthenticatable`. This will use the model's unique identifier as the session identifier and automatically perform a database lookup to restore the model from the session. 

```swift
import Fluent

final class User: Model { ... }

// Allow this model to be persisted in sessions.
extension User: ModelSessionAuthenticatable { }
```

You can add `ModelSessionAuthenticatable` to any existing model as an empty conformance. Once added, a new static method will be available for creating a `SessionAuthenticator` for that model. 

```swift
User.sessionAuthenticator()
```

This will use the application's default database for resolving the user. To specify a database, pass the identifier.

```swift
User.sessionAuthenticator(.sqlite)
```

## Website Authentication

Websites are a special case for authentication because the use of a browser restricts how you can attach credentials to a browser. This leads to two different authentication scenarios:

* the initial log in via a form
* subsequent calls authenticated with a session cookie

Vapor and Fluent provides several helpers to make this seamless.

### Session Authentication

Session authentication works as described above. You need to apply the session middleware and session authenticator to all routes that your user will access. These include any protected routes, any routes which are public but you may still want to access the user if they're logged in (to display an account button for instance) **and** login routes.

You can enable this globally in your app in **configure.swift** like so:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

These middlewares do the following:

* the sessions middleware takes the session cookie provided in the request and converts it into a session
* the session authenticator takes the session and see if there is an authenticated user for that session. If so, the middleware authenticates the request. In the response, the session authenticator sees if the request has an authenticated user and saves them in the session so they're authenticated in the next request.

### Protecting Routes

When protecting routes for an API, you traditionally return an HTTP response with a status code such as **401 Unauthorized** if the request is not authenticated. However, this isn't a very good user experience for someone using a browser. Vapor provides a `RedirectMiddleware` for any `Authenticatable` type to use in this scenario:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

This works similar to the `GuardMiddleware`. Any requests to routes registered to `protectedRoutes` that aren't authenticated will be redirected to the path provided. This allows you to tell your users to log in, rather than just providing a **401 Unauthorized**.

### Form Log In

To authenticate a user and future requests with a session, you need to log a user in. Vapor provides a `ModelCredentialsAuthenticatable` protocol to conform to. This handles log in via a form. First conform your `User` to this protocol:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

This is identical to `ModelAuthenticatable` and if you already conform to that then you don't need to do anything else. Next apply this `ModelCredentialsAuthenticator` middleware to your log in form POST request:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

This uses the default credentials authenticator to protect the login route. You must send `username` and `password` in the POST request. You can set your form up like so:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

The `CredentialsAuthenticator` extracts the `username` and `password` from the request body, finds the user from the username and verifies the password. If the password is valid, the middleware authenticates the request. The `SessionAuthenticator` then authenticates the session for subsequent requests.

## JWT

[JWT](jwt.md) provides a `JWTAuthenticator` that can be used to authenticate JSON Web Tokens in incoming requests. If you are new to JWT, check out the [overview](jwt.md).

First, create a type representing a JWT payload.

```swift
// Example JWT payload.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constants
    let expirationTime: TimeInterval = 60 * 15
    
    // Token Data
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}
```

Next, we can define a representation of the data contained in a successful login response. For now the response will only have one property which is a string representing a signed JWT.

```swift
struct ClientTokenReponse: Content {
    var token: String
}
```

Using our model for the JWT token and response, we can use a password protected login route which returns a `ClientTokenReponse` and includes a signed `SessionToken`.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req -> ClientTokenReponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Alternatively, if you don't want to use an authenticator you can have something that looks like the following.
```swift
app.post("login") { req -> ClientTokenReponse in
    // Validate provided credential for user
    // Get userId for provided user
    let payload = try SessionToken(userId: userId)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

By conforming the payload to `Authenticatable` and `JWTPayload`, you can generate a route authenticator using the `authenticator()` method. Add this to a route group to automatically fetch and verify the JWT before your route is called. 

```swift
// Create a route group that requires the SessionToken JWT.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Adding the optional [guard middleware](#guard-middleware) will require that authorization succeeded.

Inside the protected routes, you can access the authenticated JWT payload using `req.auth`. 

```swift
// Return ok reponse if the user-provided token is valid.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
