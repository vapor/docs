# Web Authentication

This guide will introduce you to session-based authentication&mdash;a method of authentication commonly used for protecting web (front-end) pages. 

## Concept

In Computer Science (especially web frameworks), the concept of Authentication means verifying the _identity_ of a user. This is not to be confused with Authorization which verifies _privileges_ to a given resource

Session-based authentication uses cookies to re-authenticate users with each request to your website. It performs this logic via a middleware that you add to your application or specific routes.

You are responsible for initially authenticating the user to your application (either manually or by using methods from the [Stateless (API)](api.md) section). Once you have authenticated the user once, the middleware will use cookies to re-authenticate the user on subsequent requests automatically. 

## Example

Let's take a look at a simple session-based authentication example.

### Pre-requisites 

In order to do session-based authentication, you must have a way to initially authenticate your user. In other words, you need a method for logging them in. The [Stateless (API)](api.md) section covers some of these methods, but it's entirely up to you. 

You will also need to have sessions configured for your application. You can learn more about this in [Vapor &rarr; Sessions](../vapor/sessions.md). Usually this will require adding the `SessionsMiddleware` and choosing a `KeyedCache`.

```swift
config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

var middlewares = MiddlewareConfig()
middlewares.use(SessionsMiddleware.self)
// ...
services.register(middlewares)
```

### Model

Once you are ready to enable session-based authentication, the first step is to conform your user model to [`SessionAuthenticatable`](https://api.vapor.codes/auth/latest/Authentication/Protocols/SessionAuthenticatable.html). 

```swift
extension User: SessionAuthenticatable { }
```

The conformance is empty since all of the required methods have default implementations. 


### Middleware

Once your model is conformed, you can use it to create an `AuthenticationSessionsMiddleware`.

```swift
// create auth sessions middleware for user
let session = User.authSessionsMiddleware()

// create a route group wrapped by this middleware
let auth = router.grouped(session)

// create new route in this route group
auth.get("hello") { req -> String in
    // 
}
```

Create a route group wrapped by this middleware using the route grouping methods. Any routes you want to support session-based authentication should use this route group.

You can also apply this middleware globally to your application if you'd like.

### Route

Inside of any route closure wrapped by the session auth middleware, we can access our authenticated model using the [`authenticated(_:)`](https://api.vapor.codes/auth/latest/Authentication/Extensions/Request.html#/s:5Vapor7RequestC14AuthenticationE13authenticatedxSgxmKAD15AuthenticatableRzlF) methods.

```swift
let user = try req.requireAuthenticated(User.self)
return "Hello, \(user.name)!"
```

Here we are using the method prefixed with `require` to throw an error if the user was not succesfully authenticated. 

If you visit this route now, you should see a message saying no user has been authenticated. Let's resolve this by creating a way for our user to login!

!!! note
    Use [`GuardAuthenticationMiddleware`](https://api.vapor.codes/auth/latest/Authentication/Classes/GuardAuthenticationMiddleware.html) to protect routes that do not call `requireAuthenticated(_:)` or otherwise require authentication.

### Login

For the sake of this example, we will just log in a pre-defined user with a fixed ID.

```swift
auth.get("login") { req -> Future<String> in
    return User.find(1, on: req).map { user in
        guard let user = user else {
            throw Abort(.badRequest)
        }
        try req.authenticate(user)
        return "Logged in"
    }
}
```

Remember that this login route must go through the `AuthenticationSessionsMiddleware`. The middleware is what will detect that we have authenticated a user and later restore the authentication automatically.

Upon visiting `/hello`, you should recieve an error message stating that you are not logged in. If you then visit `/login` first, followed by `/hello` you should see that you are now successfully logged in!

If you open the inspector, you should notice a new cookie named `"vapor-session"` has been added to your browser.


