# Persisting Auth

Persisting authentication means that a user does not need to provide their credentials with every request.
This is useful for web apps where a user should only have to log in once. 

!!! note
	For APIs, it's recommended that the user send a token with every request.
	See [Getting Started](getting-started.md) for an example about Token auth.


## Sessions

Sessions are built into Vapor by default and are an easy way to persist users in your web app.

### SessionPersistable

The first step is to conform your user model to the `SessionPersistable` protocol.

```swift
import AuthProvider

extension User: SessionPersistable {}
```

If your user is a Model, the protocol methods will be implemented automatically. However,
you can implement them if you want to do something custom.

```swift
import AuthProvider
import HTTP

extension User: SessionPersistable {
    func persist(for: Request) throws {
        // something custom
    }

    static func fetchPersisted(for: Request) throws -> Self? {
        // something custom
    }
}

```

### Middleware

Now that the user is `SessionPersistable`, we can create our middleware.

#### Sessions

First let's start by creating `SessionsMiddleware`. We'll use the `MemorySessions()` to get started.

```swift
let memory = MemorySessions()
let sessionsMiddleware = SessionsMiddleware(memory)
```

#### Persist

Now let's create the `PersistMiddleware`. This will take care of persisting our user once they've 
been authenticated. 

```swift
let persistMiddleware = PersistMiddleware(User.self)
```

Since our user conforms to `SessionPersistable` (and thus `Persistable`), we can pass it 
into this middleware's init.

#### Authentication

Now to create the authentication middleware of your choice. We'll use `PasswordAuthenticationMiddleware`
which requires an `Authorization: Basic ...` header with the user's username and password.


```swift
let passwordMiddleware = PasswordAuthenticationMiddleware(User.self)
```

!!! note:
	`User` must conform to `PasswordAuthenticatable` to be used with this middleware.
	See the [Password](password.md) section to learn more.

### Droplet

Now we can create a Droplet and add all of our middleware.

```swift
import Vapor
import Sessions
import AuthProvider

let drop = try Droplet()

let authed = drop.grouped([sessionsMiddleware, persistMiddleware, passwordMiddleware])
```

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

### Request

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
Set-Cookie: vapor-session=...

Vapor
```

Notice the `vapor-session` in the response. This can be used in subsequent requests instead of 
the username and password.



