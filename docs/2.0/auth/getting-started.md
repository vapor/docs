# Getting Started

Vapor's [Auth Provider](https://github.com/vapor/auth-provider) package makes implementing authentication and 
authorization easy and secure. It supports common auth patterns such as:

- Token (bearer) authentication
- Username + password (basic) authentication
- Permission-based authorization
- Session-based persistance 

Auth's modular, protocol-based nature also makes it a great foundation for custom auth needs.

!!! tip
    Use `vapor new <name> --template=vapor/auth-template` to create a new [project template](https://github.com/vapor/auth-template) with AuthProvider and samples included.

## Package

To use Auth, you will need to have the [Auth Provider](https://github.com/vapor/auth-provider) added to your project.
This is as simple as adding the following line to your `Package.swift` file.

```swift
.Package(url: "https://github.com/vapor/auth-provider.git", ...)
```

Check out the [Package](package.md) section for more information.

## Example

Let's take a look at how we can implement a simple, token-based authentication system using Vapor and Auth.


### User

We will start by creating a model to represent our user. If you already have a user class, you can skip this step.

```swift
import Vapor
import FluentProvider

final class ExampleUser: Model {
    let name: String

    ...
}

extension ExampleUser: Preparation { ... }
```

Here we create a very simple user with just one property: a name.

!!! seealso
	We're omitting most of `Model` and `Preparation` protocol requirements. Check out Fluent's 
	[Getting Started](../fluent/getting-started.md) for more information about these protocols.


### Token

Next let's create a model to represent our authentication tokens. These will be stored in a separate database
table or collection called "tokens".

When a user logs in, we will create a new token for them. They will then use this token on subsequent requests
instead of their username and password. 

For now, here's what our simple token model will look like.

```swift
import Vapor
import FluentProvider

final class ExampleToken: Model {
    let token: String
    let userId: Identifier
    
    var user: Parent<ExampleToken, ExampleUser> {
        return parent(id: userId)
    }

    ...
}

extension ExampleToken: Preparation { ... }
```

This token has two properties:

- token: a unique, random string that we will send in requests
- userId: the identifier for the user to whom this token belongs

!!! seealso
	We're using Fluent relations here. Check out Fluent's  [Relations](../fluent/relations.md)
	section for more information.

### Token Authenticatable

Now that we have our example user and token, we can make our user authenticatable with the token.

This might sound complicated, but it's actually pretty easy:

```swift
import AuthProvider

extension ExampleUser: TokenAuthenticatable {
    // the token model that should be queried
    // to authenticate this user
    public typealias TokenType = ExampleToken
}

```

Now that our example user is `TokenAuthenticatable`, we can move on to the next step!

### User Helper

Let's add a simple convenience method on request for accessing the authenticated user.

```swift
extension Request {
    func user() throws -> ExampleUser {
        return try auth.assertAuthenticated()
    }
}
```

This is a nice shortcut that will come in handy in a few steps.

### Middleware

To require authentication we need to add the `TokenAuthenticationMiddleware`. You can apply this middleware
to individual routes or to the entire Droplet. For simplicity, we'll apply it to the Droplet.

```swift
import Vapor
import AuthProvider
import FluentProvider

let config = try Config()

config.preparations.append(ExampleUser.self)
config.preparations.append(ExampleToken.self)

let drop = try Droplet(config)


let tokenMiddleware = TokenAuthenticationMiddleware(ExampleUser.self)

/// use this route group for protected routes
let authed = drop.grouped(tokenMiddleware)
```

Since our `ExampleUser` class is `TokenAuthenticatable`, we can pass it into the middleware's init method.

!!! seealso
	If you only want to require authentication for certain routes, look at our 
	[Route Group](../routing/group.md) section in the routing docs.

### Route

Now that we have a route group protected by our TokenMiddleware, let's add a route to
return the authenticated user's name.

```swift
authed.get("me") { req in
    // return the authenticated user's name
    return try req.user().name
}
```

!!! tip
	We're using the `.user()` convenience we added to `Request` here. It is a shortcut
	for `let user = try req.auth.assertAuthenticated(ExampleUser.self)` 


### Database

That's it! We now have a functioning authentication system. Let's add a couple of entries
to our database and test it out.

#### Users

| id | name |
|----|------|
| 1  | Bob  |

#### Tokens

| id | token | user_id |
|----|-------|---------|
| 1  | foo   | 1       |

### Request

Now we can make a request to our Vapor app.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
```

And we should get a response like.

```http
HTTP/1.1 200 OK
Content-Type: text/plain

Bob
```

#### Bad Token

To make sure it's secure, let's test using a token that's not in our database.

```http
GET /me HTTP/1.1
Authorization: Bearer not-a-token
```

And we should get a response like.

```http
HTTP/1.1 403 Forbidden
```

### Next Steps

To build this out into a production-ready authentication system, you will need to build some
additional routes for creating users and creating tokens. 

Continue on in the Auth section to learn more about different types of authentication.

