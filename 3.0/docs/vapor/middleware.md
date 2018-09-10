# Middleware

Middleware is a logic chain between the client and a Vapor route handler. It allows you to make operations on incoming requests before they get to the route handler, and on outgoing responses before they go to the client.

## Configuration, and ErrorMiddleware

Middleware is registered in your `config.swift` file. `ErrorMiddleware` is a very common example; it will take a thrown error in your software and convert it to a legible HTTP response code.

```swift
var middlewares = MiddlewareConfig()
middlewares.use(ErrorMiddleware.self)
middlewares.use(FileMiddleware.self)
// etc.
services.register(middlewares)
```

You will often run several middlewares in a single project. These middlewares are stacked up, and then registered together. The order in which middleware are listed can sometimes matter (see `CORSMiddleware` below).

## FileMiddleware

`FileMiddleware` enables the serving of assets from the Public folder of your project to the client. You might include static files like stylesheets or bitmap images here.

```swift
var middlewares = MiddlewareConfig()
middlewares.use(FileMiddleware.self)
services.register(middlewares)
```

Now that the `FileMiddleware` is registered, a file like “Public/images/logo.png” can be linked from a Leaf template as `<img src="/images/logo.png"/>`.

## CORSMiddleware

Cross-origin resource sharing (CORS) is a mechanism that allows restricted resources on a web page to be requested from another domain outside the domain from which the first resource was served. REST APIs built in Vapor will require a CORS policy in order to safely return requests to modern web browsers.

An example configuration could look something like this:

```swift
var middlewares = MiddlewareConfig()
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
middlewares.use(corsMiddleware)
middlewares.use(ErrorMiddleware.self)
services.register(middlewares)
```

Given that thrown errors are immediately returned to the client, the `CORSMiddleware` must be listed _before_ the `ErrorMiddleware`; otherwise the HTTP error response will be returned without CORS headers, and cannot be read by the browser.

## Authentication and Sessions Middleware

The Vapor Auth package has middlewares that can do basic user validation, token validation, and manage sessions. See the [Auth documentation](https://docs.vapor.codes/3.0/auth/getting-started/) for an outline of the `AuthMiddleware`.

## Middleware API

Information on how middleware works and authoring custom middleware can be found in the [Vapor API Documentation](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Middleware.html).
