# Redirect Middlewares

Included in the [AuthProvider](package.md) package are `RedirectMiddleware` and `InverseRedirectMiddleware` classes that will help you 
redirect unauthenticated or authenticated requests to a given path. This is especially useful for redirecting users away from secure
pages to a login page and vice versa.

## Redirect Middleware

Let's take a look at how to add a `RedirectMiddleware` to your application.

### Existing Auth

Since we only want this middleware to apply to secure pages, we'll apply it using route groups.

You should already have a protected area in your application using one of the authentication middlewares.

```swift
import Vapor
import AuthProvider

let drop = try Droplet()

drop.get("login") { req in
	return // some login form
}

let auth = TokenAuthenticationMiddleware(User.self)
let protected = drop.grouped([auth])
protected.get("secure") { req in
    let user = try req.auth.assertAuthenticated(User.self)
    return "Welcome to the secure page, \(user.name)"
}
```

The above snippet protects access to the page at `GET /secure` using the `TokenAuthenticationMiddleware`. 

Since we've applied `TokenAuthenticationMiddleware`, this page cannot be accessed by anyone not authenticated.
Although this is perfectly secure, we should provide a better experience for unauthenticated users. Instead of 
just showing them an error message, we can redirect them to the login page.

### Add Redirect

Creating a redirect middleware is very simple. We'll use one of the presets for redirecting a user to `/login`.

```swift
let redirect = RedirectMiddleware.login()
```

Now we just need to add this redirect middleware to our `protected` route group mentioned previously.

```swift
let protected = drop.grouped([redirect, auth])
```

!!! warning
	Make sure the redirect middleware comes _before_ the auth middleware. 

### Complete Example

Now whenever an unauthenticated user attemps to visit `GET /secure`, they will be redirected to `GET /login`.

```swift
import Vapor
import AuthProvider

let drop = try Droplet()

let redirect = RedirectMiddleware.login()
let auth = TokenAuthenticationMiddleware(TestUser.self)

let protected = drop.grouped([redirect, auth])
protected.get { req in
    let user = try req.auth.assertAuthenticated(TestUser.self)
    return "Welcome to the dashboard, \(user.name)"
}
```

### Custom Route

If your login page is not `/login` or you'd like the redirect middleware to redirect to a different type of page, 
simply use the full initializer.

```swift
let redirect = RedirectMiddleware(path: "/foo")
```

## Inverse Redirect Middleware

Complementary to the `RedirectMiddleware` is the `InverseRedirectMiddleware`. Just like you want to redirect unauthenticated
users away from secure pages, you also might want to redirect _authenticated_ users away from certain pages.

For example, if a user is already authenticated and they visit the login page, they might be confused and attempt to login again.

### Example

Here is an example of the `InverseRedirectMiddleware` being used to redirect authenticated `User`s away from the login page.

We are using the preset `.home()` convenience, which redirects the user to `GET /`.

```swift
import Vapor
import AuthProvider

let drop = try Droplet()

let redirect = InverseRedirectMiddleware.home(User.self)
let group = drop.grouped([redirect])
group.get("login") { req in
    return "Please login"
}
```

### Custom Route

If your desired page is not `/` or you'd like the inverse redirect middleware to redirect to a different type of page, 
simply use the full initializer.

```swift
let redirect = InverseRedirectMiddleware(User.self, path: "/foo")
```

