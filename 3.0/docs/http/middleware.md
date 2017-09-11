# Middleware

Middleware are a step in Vapor's responder chain. They're capable of modifying Requests/Responses, preventing the chain from continuing and transforming the data flow.

They can be employed for authorization checks, logging and a wide range of other functionalities.

## Implementing a Middleware

The following example is a middleware that will prevent all [requests](request.md) from going to their respective [responder](responder.md) unless the origin has a special header set. In the case of a missing header, [status code](status.md) 404 (not found) will be returned.

Don't secure your APIs using this example code, it's very unsafe and exclusively to be used as a test.

```swift
public final class SpecialHeaderCheckMiddleware: Middleware {
  public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
    guard request.headers["Secret-Header"] == "MagicK3y" else {
      return Response(status: .notFound)
    }

    return try next.respond(to: request)
  }
}
```

## Intercepting/transforming Responses

The following example demonstrates a middleware that creates a session token for new users.

```swift
public final class SessionTokenMiddleware: Middleware {
  func generateSessionToken() throws -> String {
    // Generate token here ...
    return token
  }

  public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
    let response = try next.respond(to: request)

    guard request.cookies["session"] != nil else {
      response.cookies["session"] = try generateSessionToken()

      return response
    }

    return response
  }
}
```
