# Content

In Vapor 3, all content types (JSON, protobuf, FormURLEncoded, Multipart, etc) are treated the same.
All you need to parse and serialize content is a `Codable` class or struct.

For this introduction, we will use JSON as an example. But keep in mind the API is the same for any supported content type.

## Request

Let's take a look at how you would parse the following HTTP request.

```http
POST /login HTTP/1.1
Content-Type: application/json

{
    "email": "user@vapor.codes",
    "password": "don't look!"
}
```

### Decode Request

First, create a struct or class that represents the data you expect.

```swift
import Foundation
import Vapor

struct LoginRequest: Content {
    var email: String
    var password: String
}
```

Then simply conform this struct or class to `Content`.
Now we are ready to decode that HTTP request.

```swift
router.post("login") { req -> Response in
    let loginRequest = try req.content(LoginRequest.self)

    print(loginRequest.email) // user@vapor.codes
    print(loginRequest.password) // don't look!

    return Response(status: .ok)
}
```

It's that simple!

### Other Request Types

Since the request in the previous example declared JSON as it's content type, 
Vapor knows to use a JSON decoder automatically. 
This same method would work just as well for the following request.

```http
POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

email=user@vapor.codes&don't+look!
```

!!! tip
    You can configure which encoders/decoders Vapor uses. Read on to learn more.

## Response

Let's take a look at how you would create the following HTTP response.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
    "name": "Vapor User",
    "email": "user@vapor.codes"
}
```

### Encode Response

Just like decoding, first create a struct or class that represents the data your expect.

```swift
import Foundation
import Vapor

struct User: Content {
    var name: String
    var email: String
}
```

Then just conform this struct or class to `Content`.
Now we are ready to encode that HTTP response.

```swift
router.get("user") { req -> Response in
    let user = User(
        name: "Vapor User", 
        email: "user@vapor.codes"
    )

    let res = Response(status: .ok)
    try res.content(user)
    return res
}
```

Even better, if you don't need to configure any properties on the response, you can 
simply return the user directly.

```swift
router.get("user") { req -> User in
    let user = User(
        name: "Vapor User", 
        email: "user@vapor.codes"
    )

    return user
}
```

### Other Response Types

Content will automatically encode as JSON by default. You can always override which content type is used
using the `as:` parameter.

```swift
try res.content(user, as: .formURLEncoded)
```

You can also change the default media type for any class or struct.

```swift
struct User: Content {
    /// See Content.defaultMediaType
    static let defaultMediaType: MediaType = .formURLEncoded

    ...
}
```

## Configuring Content

Coming soon.

