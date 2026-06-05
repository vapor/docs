# Content

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

First, create a struct or class that represents the data you expect.

```swift
import Vapor

struct LoginRequest: Content {
    var email: String
    var password: String
}
```

Then simply conform this struct or class to `Content`.
Now we are ready to decode that HTTP request.

```swift
router.post("login") { req -> Future<HTTPStatus> in
    return req.content.decode(LoginRequest.self).map(to: HTTPStatus.self) { loginRequest in
        print(loginRequest.email) // user@vapor.codes
        print(loginRequest.password) // don't look!
        return .ok
    }
}
```

We use `.map(to:)` here since `req.content.decode(_:)` returns a [future](async.md).

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

Just like decoding, first create a struct or class that represents the data that you are expecting.

```swift
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

Great job! Now you know how to encode and decode data in Vapor. 

!!! tip
    See [Vapor &rarr; Content](../vapor/content.md) for more in-depth information.

The next section in this guide is [Async](async.md).

