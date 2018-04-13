# Using Content

In Vapor 3, all content types (JSON, protobuf, URLEncodedForm, [Multipart](../multipart/getting-started.md), etc) are treated the same. All you need to parse and serialize content is a `Codable` class or struct.

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
router.post("login") { req -> Future in
    return req.content.decode(LoginRequest.self).map(to: HTTPStatus.self) { loginRequest in
        print(loginRequest.email) // user@vapor.codes
        print(loginRequest.password) // don't look!
        return .ok
    }
}
```

We use `.map(to:)` here since `req.content.decode(_:)` returns a [future](../async/getting-started.md).

### Other Request Types

Since the request in the previous example declared JSON as its content type, Vapor knows to use a JSON decoder automatically. This same method would work just as well for the following request.

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

Just like decoding, first create a struct or class that represents the data that you are expecting.

```swift
import Foundation
import Vapor

struct User: Content {
    var name: String
    var email: String
}
```

Then just conform this struct or class to `Content`. Now we are ready to encode that HTTP response.

```swift
router.get("user") { req -> User in
    return User(
        name: "Vapor User",
        email: "user@vapor.codes"
    )
}
```

### Other Response Types

Content will automatically encode as JSON by default. You can always override which content type is used
using the `as:` parameter.

```swift
try res.content.encode(user, as: .formURLEncoded)
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

Use `ContentConfig` to register custom encoder/decoders for your application. These custom coders will be used anywhere you do `content.encode`/`content.decode`.

```swift
/// Create default content config
var contentConfig = ContentConfig.default()

/// Create custom JSON encoder
var jsonEncoder = JSONEncoder()
jsonEncoder.dateEncodingStrategy = .millisecondsSince1970

/// Register JSON encoder and content config
contentConfig.use(encoder: jsonEncoder, for: .json)
services.register(contentConfig)
```