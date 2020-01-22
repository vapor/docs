# Authentication

Authentication is the act of verifying a user's identity. This is done through the verification of credentials like a username and password or unique token. Authentication (sometimes called auth/c) is distinct from authorization (auth/z) which is the act of verifying a previously authenticated user's permissions to perform certain tasks.

## Introduction

Vapor's Authentication API provides support for authenticating a user via the `Authorization` header, using [Basic](https://tools.ietf.org/html/rfc7617) and [Bearer](https://tools.ietf.org/html/rfc6750). It also supports authenticating a user via the data decoded from the [Content](/content.md) API.

Authentication is implemented by creating an `Authenticator` which contains the verification logic. An authenticator is then capable of creating middleware which can be used to protect individual route groups or an entire app. The following authenticator helpers ship with Vapor:

|Protocol|Description|
|-|-|
|`RequestAuthenticator`|Base authenticator capable of creating middleware.|
|[`BasicAuthenticator`](#basic)|Authenticates Basic authorization header.|
|[`BearerAuthenticator`](#bearer)|Authenticates Bearer authorization header.|
|`UserTokenAuthenticator`|Authenticates a token type with associated user.|
|`CredentialsAuthenticator`|Authenticates a credentials payload from the request body.|

If authentication is successful, the authenticator returns the verified user. This user can then be accessed using `req.auth.get(_:)` in routes protected by the authenticator's middleware. If authentication fails, `nil` is returned and the user is not available via `req.auth`. 

## Authenticatable

To use the Authentication API, you first need a user type that conforms to `Authenticatable`. This can be a `struct`, `class`, or even a Fluent `Model`. The following examples assume this simple `User` struct that has one property: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Each example below will create an authenticator named `UserAuthenticator`. 

### Route

Authenticators can generate a middleware for protecting routes.

```swift
let protected = app.grouped(UserAuthenticator().middleware())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` is used to fetch the authenticated `User`. If authentication failed, this method will throw an error, protecting the route. 

### Guard Middleware

You can also use `GuardMiddleware` in your route group to ensure that a user has been authenticated before reaching your route handler.

```swift
let protected = app.grouped(UserAuthenticator().middleware())
    .grouped(User.guardMiddleware())
```

Requiring authentication is not done by the authenticator's middleware to allow for composition of authenticators. Read more about [composition](#composition) below.

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
    ) -> EventLoopFuture<User?> {
       guard basic.username == "test" && basic.password == "secret" else {
           return request.eventLoop.makeSucceededFuture(nil)
       }
       let test = User(name: "Vapor")
       return request.eventLoop.makeSucceededFuture(test)
   }
}
```

This protocol requires you to implement `authenticate(basic:for:)` which will be called when an incoming request contains the `Authorization: Basic ...` header. A `BasicAuthorization` struct containing the username and password is passed to the method.

In this test authenticator, the username and password are tested against hard-coded values. In a real authenticator, you might check against a database or external API. This is why the `authenticate` method allows you to return a future. 

!!! tip
    Passwords should never be stored in a database as plaintext. Always use password hashes for comparison.

If the authentication parameters are correct, in this case matching the hard-coded values, a `User` named Vapor is returned. If the authentication parameters do not match, `nil` is returned, which signifies authentication failed. 

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
    ) -> EventLoopFuture<User?> {
       guard bearer.token == "foo" else {
           return request.eventLoop.makeSucceededFuture(nil)
       }
       let test = User(name: "Vapor")
       return request.eventLoop.makeSucceededFuture(test)
   }
}
```

This protocol requires you to implement `authenticate(bearer:for:)` which will be called when an incoming request contains the `Authorization: Bearer ...` header. A `BearerAuthorization` struct containing the token is passed to the method.

In this test authenticator, the token is tested against a hard-coded value. In a real authenticator, you might verify the token by checking against a database or using cryptographic measures, like is done with JWT. This is why the `authenticate` method allows you to return a future. 

!!! tip
	When implementing token verification, it's important to consider horizontal scalability. If your application needs to handle many users concurrently, authentication can be a potential bottlneck. Consider how your design will scale across multiple instances of your application running at once.

If the authentication parameters are correct, in this case matching the hard-coded value, a `User` named Vapor is returned. If the authentication parameters do not match, `nil` is returned, which signifies authentication failed. 

If you add this authenticator to your app, and test the route defined above, you should see the name `"Vapor"` returned for a successful login. If the credentials are not correct, you should see a `401 Unauthorized` error.

## Composition

Multiple authenticators can be composed (combined together) to create more complex endpoint authentication. Since an authenticator's middleware will not reject the request if authentication fails, more than one of these middleware can be chained together. Authenticators can composed in two key ways. 

### Composing Methods


The first method of authentication composition is chaining more than one authenticator for the same user type. Take the following example:

```swift
app.grouped(UserPasswordAuthenticator().middleware())
    .grouped(UserTokenAuthenticator().middleware())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Do something with user.
}
```

This example assumes two authenticators `UserPasswordAuthenticator` and `UserTokenAuthenticator` that both authenticate `User`. The middleware for both of these authenticators is added to the route group. Finally, `GuardMiddleware` is added after the authenticators' middleware to require that `User` was successfully authenticated. 

This composition of authenticators results in a route that can be accessed by either password or token. Such a route could allow a user to login and generate a token, then continue to use that token to generate new tokens.

### Composing Users

The second method of authentication composition is chaining authenticators for different user types. Take the following example:

```swift
app.grouped(AdminAuthenticator().middleware())
    .grouped(UserAuthenticator().middleware())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Do something.
}
```

This example assumes two authenticators `AdminAuthenticator` and `UserAuthenticator` that authenticate `Admin` and `User`, respectively. The middleware for both of these authenticators is added to the route group. Instead of using `GuardMiddleware`, a check in the route handler is added to see if either `Admin` or `User` were authenticated. If not, an error is thrown.

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
