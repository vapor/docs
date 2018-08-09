# API Authentication

This guide will introduce you to stateless authentication&mdash;a method of authentication commonly used for protecting API endpoints. 

## Concept

In Computer Science (especially web frameworks), the concept of Authentication means verifying the _identity_ of a user. This is not to be confused with Authorization which verifies _privileges_ to a given resource

This package allows you to implement stateless authorization using the following tools:

- *`"Authorization"` header*: Used to send credentials in an HTTP request.
- *Middleware*: Detects credentials in request and fetches authenticated user.
- *Model*: Represents an authenticated user and its identifying information. 

### Authorization Header

This packages makes use of two common authorization header formats: basic and bearer.

#### Basic

Basic authorization contains a username and password. They are joined together by a `:` and then base64 encoded. 

A basic authorization header containing the username `Alladin` and password `OpenSesame` would look like this:

```http
Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l
```

Although basic authorization can be used to authenticate each request to your server, most web applications usually create an ephemeral token for this purpose instead. 

#### Bearer

Bearer authorization simply contains a token. A bearer authorization header containing the token `cn389ncoiwuencr` would look like this:

```http
Authorization: Bearer cn389ncoiwuencr
```

The bearer authorization header is very common in APIs since it can be sent easily with each request and contain an ephemeral token. 


### Middleware

The usage of Middleware is critical to this package. If you are not familiar with how Middleware works in Vapor, feel free to brush up by reading [Vapor &rarr; Middleware](../vapor/middleware.md).

Authentication middleware is responsible for reading the credentials from the request and fetching the identifier user. This usually means checking the `"Authorization"` header, parsing the credentials, and doing a database lookup. 

For each model / authentication method you use, you will add one middleware to your application. All of this package's middlewares are composable, meaning you can add multiple middlewares to one route and they will work together. If one middleware fails to authorize a user, it will simply forward the request for the next middleware to try.

If you would like to ensure that a certain model's authentication has succeeded _before_ running your route, you must add an instance of [`GuardAuthenticationMiddleware`](https://api.vapor.codes/auth/latest/Authentication/Classes/GuardAuthenticationMiddleware.html).

### Model

Fluent models are _what_ the middlewares authenticate. Learn more about models by reading [Fluent &rarr; Models](../fluent/models.md). If authentication is succesful, the middleware will have fetched your model from the database and stored it on the request. This means you can access an authenticated model synchronously in your route. 

In your route closure, you use the following methods to check for authentication:

- `authenticated(_:)`: Returns type if authenticated, `nil` if not.
- `isAuthenticated(_:)`: Returns `true` if supplied type is authenticated.
- `requireAuthenticated(_:)`: Returns type if authenticated, `throws` if not.

Typical usage looks like the following:

```swift
// use middleware to protect a group
let protectedGroup = router.group(...)

// add a protected route
protectedGroup.get("test") { req in
    // require that a User has been authed by middleware or throw
    let user = try req.requireAuthenticated(User.self)

    // say hello to the user
    return "Hello, \(user.name)."

}
```

## Methods

This package supports two basic types of stateless authentication. 

- _Token_: Uses the bearer authorization header.
- _Password_: Uses the basic authorization header.

For each authentication type, there is a separate middleware and model protocol.

### Password Authentication

Password authentication uses the basic authorization header (username and password) to verify a user. With this method, the username and password must be sent with each request to a protected endpoint.

To use password authentication, you will first need to conform your Fluent model to `PasswordAuthenticatable`. 

```swift
extension User: PasswordAuthenticatable {
    /// See `PasswordAuthenticatable`.
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }
    
    /// See `PasswordAuthenticatable`.
    static var passwordKey: WritableKeyPath<User, String> {
        return \.passwordHash
    }
}
```

Note that the `passwordKey` should point to the _hashed_ password. Never store passwords in plaintext. 

Once you have created an authenticatable model, the next step is to add middleware to your protected route.

```swift
// Use user model to create an authentication middleware
let password = User.basicAuthMiddleware(using: BCryptDigest())

// Create a route closure wrapped by this middleware 
router.grouped(password).get("hello") { req in
    ///
}
```

Here we are using `BCryptDigest` as the [`PasswordVerifier`](https://api.vapor.codes/auth/latest/Authentication/Protocols/PasswordVerifier.html) since we are assuming the user's password is stored as a BCrypt hash. 

Now, to fetch the authenticated user in the route closure, you can use [`requireAuthenticated(_:)`](https://api.vapor.codes/auth/latest/Authentication/Extensions/Request.html#/s:5Vapor7RequestC14AuthenticationE20requireAuthenticatedxxmKAD15AuthenticatableRzlF). 

```swift
let user = try req.requireAuthenticated(User.self)
return "Hello, \(user.name)."
```

The `requireAuthenticated` method will automatically throw an appropriate unauthorized error if the valid credentials were not supplied. Because of this, using [`GuardAuthenticationMiddleware`](https://api.vapor.codes/auth/latest/Authentication/Classes/GuardAuthenticationMiddleware.html) to protect the route from unauthenticated access is not required. 

### Token Authentication

Token authentication uses the bearer authorization header (token) to lookup a token and its related user. With this method, the token must be sent with each request to a protected endpoint.

Unlike password authentication, token authentication relies on _two_ Fluent models. One for the token and one for the user. The token model should be a _child_ of the user model.

Here is an example of a very basic `User` and associated `UserToken`. 

```swift
struct User: Model {
    var id: Int?
    var name: String
    var email: String
    var passwordHash: String

    var tokens: Children<User, UserToken> {
        return children(\.userID)
    }
}

struct UserToken: Model {
    var id: Int?
    var string: String
    var userID: User.ID

    var user: Parent<UserToken, User> {
        return parent(\.userID)
    }
}
```

The first step to using token authentication is to conform your user and token models to their respective `Authenticatable` protocols.

```swift
extension UserToken: Token {
    /// See `Token`.
    typealias UserType = User
    
    /// See `Token`.
    static var tokenKey: WritableKeyPath<UserToken, String> {
        return \.string
    }
    
    /// See `Token`.
    static var userIDKey: WritableKeyPath<UserToken, User.ID> {
        return \.userID
    }
}
```

Once the token is conformed to `Token`, setting up the user model is easy.

```swift
extension User: TokenAuthenticatable {
    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}
```

Once you have conformed your models, the next step is to add middleware to your protected route.

```swift
// Use user model to create an authentication middleware
let token = User.tokenAuthMiddleware()

// Create a route closure wrapped by this middleware 
router.grouped(token).get("hello") {
    //
}
```

Now, to fetch the authenticated user in the route closure, you can use [`requireAuthenticated(_:)`](https://api.vapor.codes/auth/latest/Authentication/Extensions/Request.html#/s:5Vapor7RequestC14AuthenticationE20requireAuthenticatedxxmKAD15AuthenticatableRzlF). 

```swift
let user = try req.requireAuthenticated(User.self)
return "Hello, \(user.name)."
```

The `requireAuthenticated` method will automatically throw an appropriate unauthorized error if the valid credentials were not supplied. Because of this, using [`GuardAuthenticationMiddleware`](https://api.vapor.codes/auth/latest/Authentication/Classes/GuardAuthenticationMiddleware.html) to protect the route from unauthenticated access is not required. 
