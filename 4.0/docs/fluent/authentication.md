# Authentication using Fluent

Fluent builds on Vapor's [Authentication](../authentication.md) API to provide an easy, customizable way to do user authentication using database models. 

## Introduction

Fluent defines two protocols `ModelUser` and `ModelUserToken` which can be added to your existing models. Conforming your models to these protocols allows for the creation of authenticators which generate middleware for protecting endpoints. 

`ModelUserToken` authenticates with a bearer token. This is what you use to protect most of your endpoints. `ModelUser` authenticates with username and password and is used by a single endpoint for generating tokens. 

This guide assumes you are familiar with Fluent and have successfully configured your app to use a database. If you are new to Fluent, start with the [overview](overview.md).

## User

You will need a model representing the user that will be authenticated. For this guide, we'll be using the following model:

```swift
import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"

    @ID(key: "id")
    var id: Int?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: Int? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

This model must be able to store a username, in this case an email, and a password hash. The corresponding migration for this model is here:

```swift
import Vapor
import Fluent

extension User {
    struct Migration: Fluent.Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema("users")
                .field("id", .int, .identifier(auto: true))
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema("users").delete()
        }
    }
}
```

Don't forget to add the migration to `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

The first thing you will need is an endpoint to create new users. Let's use `POST /users`. Create a `Content` struct representing the data this endpoint expects. Learn more about the Content API [here](../content.md).

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

If you like, you can conform this struct to `Validatable` to add validation requirements. Learn more about the Validation API [here](../validation.md).

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(3...) && .alphanumeric)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

Now you can create the `POST /users` endpoint. 

```swift
import Vapor

app.post("users") { req -> EventLoopFuture<User> in
    try User.Create.validate(req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(password: create.password)
    )
    return user.save(on: req.db)
        .map { user }
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
    "password": "secret",
    "confirmPassword": "secret"
}
```

### Authenticator

Now that you have a user model and an endpoint to create new users, let's conform the model to `ModelUser`. This will allow for the model to be authenticated using username and password.

```swift
extension User: ModelUser {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

This extension adds `ModelUser` conformance to `User`. The first two properties specify which fields should be used for storing the username and password hash respectively. The `\` notation creates a key path to the fields that Fluent can use to access them.

The last requirement is a method for verifying plaintext passwords sent in the basic authentication header. Since we're using Bcrypt to hash the password during signup, we'll use Bcrypt to verify that the supplied password matches the stored password hash.

Now that the `User` conforms to `ModelUser`, we can create an authenticator to protect the login route.

```swift
let passwordProtected = app.grouped(User.authenticator().middleware())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelUser` adds a static method `authenticator()` for creating the authenticator. We can then use `middleware()` to generate a middleware from the authenticator. Learn more about the Authentication API [here](../authentication.md).

Test that this route works by sending the following request.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ=
```

This request passes the username `test@vapor.codes` and password `secret` via the basic authentication header. You should see the previously created user returned.

While you could theoretically use basic authentication to protect all of your endpoints, it's recommended to use a separate token instead. This minimizes how often you must send the user's sensitive password over the Internet. It also makes authentication much faster since you only need to perform password hashing during login.

## User Token

Create a new model for representing user tokens.

```swift
final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: "id")
    var id: Int?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: Int? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

This model must have a `value` field for storing the token's unique string. It must also have a parent-relation to the user model. You may add additional properties to this token as you see fit, such as an expiration date. 

Next, create a migration for this model.

```swift
extension UserToken {
    struct Migration: Fluent.Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema("user_tokens")
                .field("id", .int, .identifier(auto: true))
                .field("value", .string, .required)
                .field("user_id", .int, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema("user_tokens").delete()
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
let passwordProtected = app.grouped(User.authenticator().middleware())
passwordProtected.post("login") { req -> EventLoopFuture<UserToken> in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    return token.save(on: req.db)
        .map { token }
}
```

Test that this route works by using the same login request from above. You should now get a token upon logging in that looks something like:

```
8gtg300Jwdhc/Ffw784EXA==
```

Hold onto the token you get as we'll use it shortly.

### Authenticator

Conform `UserToken` to `ModelUserToken`. This will allow for tokens to authenticate your `User` model.

```swift
extension UserToken: ModelUserToken {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user
}
```

The first protocol requirement specifies which field stores the token's unique value. This is the value that will be sent in the bearer authentication header. The second requirement specifies the parent-relation to the `User` model. This is how Fluent will look up the authenticated user.

Now that the token conforms to `ModelUserToken`, you can create an authenticator and middleware for protecting routes.

Create a new endpoint `GET /me` for getting the currently authenticated user.

```swift
let tokenProtected = app.grouped(UserToken.authenticator().middleware())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Similar to `User`, `UserToken` now has a static `authenticator()` that can be generate a middleware with `middleware()`. The middleware will attempt to find a matching `UserToken` using the value provided in the bearer authentication header. If it finds a match, it will fetch the related `User` and authenticate it. 

Test that this route works by sending the following HTTP request where the token is the value you saved from the `POST /login` request. 

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

You should see the authenticated `User` returned. 
