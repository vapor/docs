# Errors

Vapor builds on Swift's `Error` protocol for error handling. Route handlers can either `throw` an error or return a failed `EventLoopFuture`. Throwing or returning a Swift `Error` will result in a `500` status response and the error will be logged. `AbortError` and `DebuggableError` can be used to change the resulting response and logging respectively. The handling of errors is done by `ErrorMiddleware`. This middleware is added to the application by default and can be replaced with custom logic if desired. 

## Abort

Vapor provides a default error struct named `Abort`. This struct conforms to both `AbortError` and `DebuggableError`. You can initialize it with an HTTP status and optional failure reason.

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

In old asynchronous situations where throwing is not supported and you must return an `EventLoopFuture`, like in a `flatMap` closure, you can return a failed future.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))    
}
return user.save()
```

Vapor includes a helper extension for unwrapping futures with optional values: `unwrap(or:)`. 

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap 
{ user in
    // Non-optional User supplied to closure.
}
```

If `User.find` returns `nil`, the future will be failed with the supplied error. Otherwise, the `flatMap` will be supplied with a non-optional value. If using `async`/`await` then you can handle optionals as normal:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

By default, any Swift `Error` thrown or returned by a route closure will result in a `500 Internal Server Error` response. When built in debug mode, `ErrorMiddleware` will include a description of the error. This is stripped out for security reasons when the project is built in release mode. 

To configure the resulting HTTP response status or reason for a particular error, conform it to `AbortError`. 

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## Debuggable Error

`ErrorMiddleware` uses the `Logger.report(error:)` method for logging errors thrown by your routes. This method will check for conformance to protocols like `CustomStringConvertible` and `LocalizedError` to log readable messages.

To customize error logging, you can conform your errors to `DebuggableError`. This protocol includes a number of helpful properties like a unique identifier, source location, and stack trace. Most of these properties are optional which makes adopting the conformance easy. 

To best conform to `DebuggableError`, your error should be a struct so that it can store source and stack trace information if needed. Below is an example of the aforementioned `MyError` enum updated to use a `struct` and capture error source information.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` has several other properties like `possibleCauses` and `suggestedFixes` that you can use to improve the debuggability of your errors. Take a look at the protocol itself for more information.

## Error Middleware

`ErrorMiddleware` is one of the only two middlewares added to your application by default. This middleware converts Swift errors that have been thrown or returned by your route handlers into HTTP responses. Without this middleware, errors thrown will result in the connection being closed without a response. 

To customize error handling beyond what `AbortError` and `DebuggableError` provide, you can replace `ErrorMiddleware` with your own error handling logic. To do this, first remove the default error middleware by manually initializing `app.middleware`. Then, add your own error handling middleware as the first middleware to your application.

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

Very few middleware should go _before_ the error handling middleware. A notable exception to this rule is `CORSMiddleware`.
