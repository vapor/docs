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

## Creating a Middleware

Vapor ships with a few and handy middlewares, but sometimes you would need to create your own because of the requirements of your application. For example you could need a middleware that prevents any non-admin user to reach a group of routes.

> We recommend creating a `Middleware` folder inside your `Sources/App` directory to keep your code organised

Middleware are structs that conforms to Vapor's `Middleware` protocol and passes the request to the next middleware in the chain.

Using the example mentioned before, let's block access to the user if it's not an admin:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    public init() {}
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
    	
	if req.auth.require().role != "admin" {
	    return req.eventLoop.future(Response(status: .unauthorized))
	}
	
	return next.respond(to: request)
    }
    
}
```

If you want to modify the response, for example to add a custom header to all your outgoing responses from the routes this middleware is applied to, you should wait until the response comes back from the other middlewares:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    public init() {}
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {

	return next.respond(to: request) { response in
	    response.headers.add(name: "My-App-Version", value: "v2.5.9")
	    
	    return response
	}
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

// Only add this if you want to enable the default per-route logging
let routeLogging = RouteLoggingMiddleware(logLevel: .info)

// Add the default error middleware
let error = ErrorMiddleware.default(environment: app.environment)
// Clear any existing middleware.
app.middleware = .init()
app.middleware.use(cors)
app.middleware.use(routeLogging)
app.middleware.use(error)
```

Given that thrown errors are immediately returned to the client, the `CORSMiddleware` must be listed _before_ the `ErrorMiddleware`. Otherwise, the HTTP error response will be returned without CORS headers, and cannot be read by the browser.
