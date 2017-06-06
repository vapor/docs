# Username + Password (Basic) Auth

The `Authorization: Basic ...` header can be used to send username and password credentials
for authentication.

This page will show you how to use this type of authentication in your web app.

!!! note:
	Sending and storing passwords should be avoided wherever possible. Use tokens or
	sessions persistance to prevent the need for sending the password in every request.

## Password Authenticatable

Start by conforming your user model to the `PasswordAuthenticatable` protocol.

```swift
import AuthProvider

extension User: PasswordAuthenticatable { }
```

### Custom

If your user conforms to `Model`, all of the required methods will be implemented automatically. However,
you can implement them if you want to do something custom.


```swift
extension User: PasswordAuthenticatable {
    /// Return the user matching the supplied
    /// username and password
    static func authenticate(_: Password) throws -> Self {
    	// something custom
	}

    /// The entity's hashed password used for
    /// validating against Password credentials
    /// with a PasswordVerifier
    var hashedPassword: String? {
    	// something custom
    }

    /// The key under which the user's username,
    /// email, or other identifing value is stored.
    static var usernameKey: String {
    	// something custom
    }

    /// The key under which the user's password
    /// is stored.
    static var passwordKey: String {
    	// something custom
    }

    /// Optional password verifier to use when
    /// comparing plaintext passwords from the 
    /// Authorization header to hashed passwords
    /// in the database.
    static var passwordVerifier: PasswordVerifier? {
    	// some hasher
    }
}
```

## Middleware

Once your model conforms to the `PasswordAuthenticatable` protocol, you can create the middleware.


```swift
import Vapor
import AuthProvider

let drop = try Droplet()

let passwordMiddleware = PasswordAuthenticationMiddleware(User.self)

let authed = try drop.grouped(passwordMiddleware)

try drop.run()
```

All routes added to the `authed` route group will be protected by the password middleware.

!!! seealso
	If you only want to globally require the password middleware, checkout the
	[Middleware Config](../http/middleware.md/#config) section in the HTTP docs.

### Route

Now you can add a route to return the authenticated user.

```swift
authed.get("me") { req in
    // return the authenticated user
    return try req.auth.assertAuthenticated(User.self)
}
```

Call `req.user.authenticated(User.self)` to get access to the authenticated user.


## Request

Now we can make a request to our Vapor app.

```http
GET /me HTTP/1.1
Authorization: Basic dmFwb3I6Zm9v 
```

!!! note
	`dmFwb3I6Zm9v` is "vapor:foo" base64 encoded where "vapor" is the username and 
	"foo" is the password. This is the format of Basic authorization headers.

And we should get a response like.

```http
HTTP/1.1 200 OK
Content-Type: text/plain

Vapor
```


