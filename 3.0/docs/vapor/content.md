# Using Content

In Vapor 3, all content types (JSON, protobuf, [URLEncodedForm](../url-encoded-form/getting-started.md), [Multipart](../multipart/getting-started.md), etc) are treated the same. All you need to parse and serialize content is a `Codable` class or struct.

For this introduction, we will use mostly JSON as an example. But keep in mind the API is the same for any supported content type.

## Server

This first section will go over decoding and encoding messages sent between your server and connected clients. See the [client](#client) section for encoding and decoding content in messages sent to external APIs.

### Request

Let's take a look at how you would parse the following HTTP request sent to your server.

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

Notice the key names exactly match the keys in the request data. The expected data types also match. Next conform this struct or class to `Content`.

#### Decode

Now we are ready to decode that HTTP request. Every [`Request`](https://api.vapor.codes/vapor/latest/Vapor/Classes/Request.html) has a [`ContentContainer`](https://api.vapor.codes/vapor/latest/Vapor/Structs/ContentContainer.html) that we can use to decode content from the message's body.

```swift
router.post("login") { req -> Future<HTTPStatus> in
    return req.content.decode(LoginRequest.self).map { loginRequest in
        print(loginRequest.email) // user@vapor.codes
        print(loginRequest.password) // don't look!
        return HTTPStatus.ok
    }
}
```

We use `.map(to:)` here since `decode(...)` returns a [future](../async/getting-started.md). 

!!! note
    Decoding content from requests is asynchronous because HTTP allows bodies to be split into multiple parts using chunked transfer encoding. 

#### Router

To help make decoding content from incoming requests easier, Vapor offers a few extensions on [`Router`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Router.html) to do this automatically.

```swift
router.post(LoginRequest.self, at: "login") { req, loginRequest in
    print(loginRequest.email) // user@vapor.codes
    print(loginRequest.password) // don't look!
    return HTTPStatus.ok
}
```

#### Detect Type

Since the HTTP request in this example declared JSON as its content type, Vapor knows to use a JSON decoder automatically. This same method would work just as well for the following request.

```http
POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

email=user@vapor.codes&don't+look!
```

All HTTP requests must include a content type to be valid. Because of this, Vapor will automatically choose an appropriate decoder or error if it encounters an unknown media type.

!!! tip
    You can [configure](#configure) the default encoders and decoders Vapor uses.
    
#### Custom

You can always override Vapor's default decoder and pass in a custom one if you want.

```swift
let user = try req.content.decode(User.self, using: JSONDecoder())
print(user) // Future<User>
```

### Response

Let's take a look at how you would create the following HTTP response from your server.

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

Then just conform this struct or class to `Content`. 

#### Encode

Now we are ready to encode that HTTP response.

```swift
router.get("user") { req -> User in
    return User(name: "Vapor User", email: "user@vapor.codes")
}
```

This will create a default `Response` with `200 OK` status code and minimal headers. You can customize the response using a convenience `encode(...)` method.

```swift
router.get("user") { req -> Future<Response> in
    return User(name: "Vapor User", email: "user@vapor.codes")
        .encode(status: .created)
}
```

#### Override Type

Content will automatically encode as JSON by default. You can always override which content type is used
using the `as:` parameter.

```swift
try res.content.encode(user, as: .urlEncodedForm)
```

You can also change the default media type for any class or struct.

```swift
struct User: Content {
    /// See `Content`.
    static let defaultContentType: MediaType = .urlEncodedForm

    ...
}
```

## Client

Encoding content to HTTP requests sent by [`Client`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html)s is similar to encoding HTTP responses returned by your server. 

### Request

Let's take a look at how we can encode the following request.

```http
POST /login HTTP/1.1
Host: api.vapor.codes
Content-Type: application/json

{
    "email": "user@vapor.codes",
    "password": "don't look!"
}
```

#### Encode

First, create a struct or class that represents the data you expect.

```swift
import Vapor

struct LoginRequest: Content {
    var email: String
    var password: String
}
```

Now we are ready to make our request. Let's assume we are making this request inside of a route closure, so we will use the _incoming_ request as our container. 

```swift
let loginRequest = LoginRequest(email: "user@vapor.codes", password: "don't look!")
let res = try req.client().post("https://api.vapor.codes/login") { loginReq in
    // encode the loginRequest before sending
    try loginReq.content.encode(loginRequest)
}
print(res) // Future<Response>
```

### Response

Continuing from our example in the encode section, let's see how we would decode content from the client's response.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
    "name": "Vapor User",
    "email": "user@vapor.codes"
}
```

First of course we must create a struct or class to represent the data.

```swift
import Vapor

struct User: Content {
    var name: String
    var email: String
}
```

#### Decode

Now we are ready to decode the client response.

```swift
let res: Future<Response> // from the Client

let user = res.flatMap { try $0.content.decode(User.self) }
print(user) // Future<User>
```

### Example

Let's now take a look at our complete [`Client`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html) request that both encodes and decodes content.

```swift
// Create the LoginRequest data
let loginRequest = LoginRequest(email: "user@vapor.codes", password: "don't look!")
// POST /login
let user = try req.client().post("https://api.vapor.codes/login") { loginReq in 
    // Encode Content before Request is sent
    return try loginReq.content.encode(loginRequest) 
}.flatMap { loginRes in
    // Decode Content after Response is received
    return try loginRes.content.decode(User.self) 
}
print(user) // Future<User>
```

## Query String

URL-Encoded Form data can be encoded and decoded from an HTTP request's URI query string just like content. All you need is a class or struct that conforms to [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html). In these examples, we will be using the following struct.

```swift
struct Flags: Content {
     var search: String?
     var isAdmin: Bool?
}
```

### Decode

All [`Request`](https://api.vapor.codes/vapor/latest/Vapor/Classes/Request.html)s have a [`QueryContainer`](https://api.vapor.codes/vapor/latest/Vapor/Structs/QueryContainer.html) that you can use to decode the query string.

```swift
let flags = try req.query.decode(Flags.self)
print(flags) // Flags
```

### Encode

You can also encode content. This is useful for encoding query strings when using [`Client`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Client.html).

```swift
let flags: Flags ...
try req.query.encode(flags)
```

## Dynamic Properties

One of the most frequently asked questions regarding `Content` is:

> How do I add a property to just this response?

The way Vapor 3 handles `Content` is based entirely on `Codable`. At no point (that is publically accessible) is your data in an arbitrary data structure like `[String: Any]` that you can mutate at will. Because of this, all data structures that your app accepts and returns _must_ be statically defined.

Let's take a look at a common scenario to better understand this. Very often when you are creating a user, there are a couple different data formats required:

- create: password should be supplied twice to check values match
- internal: you should store a hash not the plaintext password
- public: when listing users, the password hash should not be included

To do this, you should create three types.

```swift
// Data required to create a user
struct UserCreate: Content {
    var email: String
    var password: String
    var passwordCheck: String
}

// Our internal User representation
struct User: Model {
    var id: Int?
    var email: String
    var passwordHash: Data
}

// Public user representation
struct PublicUser: Content {
    var id: Int
    var email: String
}

// Create a router for POST /users
router.post(UserCreate.self, at: "users") { req, userCreate -> PublicUser in
    guard userCreate.password == passwordCheck else { /* some error */ }
    let hasher = try req.make(/* some hasher */)
    let user = try User(
        email: userCreate.email, 
        passwordHash: hasher.hash(userCreate.password)
    )
    // save user
    return try PublicUser(id: user.requireID(), email: user.email)
}
```

For other methods such as `PATCH` and `PUT`, you may want to create additional types to supports the unique semantics.

### Benefits

This method may seem a bit verbose at first when compared to dynamic solutions, but it has a number of key advantages:

- **Statically Typed**: Very little validation is needed on top of what Swift and Codable do automatically.
- **Readability**: No need for Strings and optional chaining when working with Swift types.
- **Maintainable**: Large projects will appreciate having this information separated and clearly stated.
- **Shareable**: Types defining what content your routes accept and return can be used to conform to specifications like OpenAPI or even be shared directly with clients written in Swift.
- **Performance**: Working with native Swift types is much more performant than mutating `[String: Any]` dictionaries.

## JSON

JSON is a very popular encoding format for APIs and the way in which dates, data, floats, etc are encoded is non-standard. Because of this, Vapor makes it easy to use custom [`JSONDecoder`](https://api.vapor.codes/vapor/latest/Vapor/Extensions/JSONDecoder.html#/s:5Vapor6customXeXeFZ)s when you interact with other APIs.

```swift
// Conforms to Encodable
let user: User ... 
// Encode JSON using custom date encoding strategy
try req.content.encode(json: user, using: .custom(dates: .millisecondsSince1970))
```

You can also use this method for decoding.

```swift
// Decode JSON using custom date encoding strategy
let user = try req.content.decode(json: User.self, using: .custom(dates: .millisecondsSince1970))
```

If you would like to set a custom JSON encoder or decoder globally, you can do so using [configuration](#configure).

## Configure

Use [`ContentConfig`](https://api.vapor.codes/vapor/latest/Vapor/Structs/ContentConfig.html) to register custom encoder/decoders for your application. These custom coders will be used anywhere you do `content.encode`/`content.decode`.

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