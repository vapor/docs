# Middleware

Middleware is a logic chain between the client and a Vapor route handler. It allows you to perform operations on incoming requests before they get to the route handler and on outgoing responses before they go to the client.

## Configuration

Middleware can be registered globally (on every route) in `configure(_:)` using `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

You can also add middleware to individual routes using route groups.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// This request has passed through MyMiddleware.
}
```

### Order

The order in which middleware are added is important. Requests coming into your application will go through the middleware in the order they are added. Responses leaving your application will go back through the middleware in reverse order. Route-specific middleware always runs after application middleware. Take the following example:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in 
		"Hello, middleware."
	}
}
```

A request to `GET /hello` will visit middleware in the following order:

```
Request → A → B → C → Handler → C → B → A → Response
```

Middleware can be _prepended_ as well, which is useful when you want to add a middleware _before_ the default middleware vapor adds automatically:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Creating a Middleware

Vapor ships with a few useful middlewares, but you might need to create your own because of the requirements of your application. For example you could create a middleware that prevents any non-admin user from accessing a group of routes.

> We recommend creating a `Middleware` folder inside your `Sources/App` directory to keep your code organised

Middleware are types that conform to Vapor's `Middleware` or `AsyncMiddleware` protocol. They are inserted into the responder chain and can access and manipulate a request before it reaches a route handler and access and manipulate a response before it is returned.

Using the example mentioned above, create a middleware to block access to the user if they're not an admin:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

Or if using `async`/`await` you can write:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

If you want to modify the response, for example to add a custom header, you can use a middleware for this too. Middlewares can wait until the response is received from the responder chain and manipulate the response:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

Or if using `async`/`await` you can write:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

`FileMiddleware` enables the serving of assets from the Public folder of your project to the client. You might include static files like stylesheets or bitmap images here.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Once `FileMiddleware` is registered, a file like `Public/images/logo.png` can be linked from a Leaf template as `<img src="/images/logo.png"/>`.

## CORS Middleware

Cross-origin resource sharing (CORS) is a mechanism that allows restricted resources on a web page to be requested from another domain outside the domain from which the first resource was served. REST APIs built in Vapor will require a CORS policy in order to safely return requests to modern web browsers.

An example configuration could look something like this:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors middleware should come before default error middleware using `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Given that thrown errors are immediately returned to the client, the `CORSMiddleware` must be listed _before_ the `ErrorMiddleware`. Otherwise, the HTTP error response will be returned without CORS headers, and cannot be read by the browser.
