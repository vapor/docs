# Using JWT

JSON Web Tokens are a great tool for implementing _decentralized_ authentication and authorization. Once you are finished configuring your app to use the JWT package (see [JWT &rarr; Getting Started](getting-started.md)), you are ready to begin using JWTs in your app.

## Structure

Like other forms of token-based auth, JWTs are sent using the bearer authorization header. 

```http
GET /hello HTTP/1.1
Authorization: Bearer <token>
...
```

In the example HTTP request above, `<token>` would be replaced by the serialized JWT. [jwt.io](https://jwt.io) hosts an online tool for parsing and serializing JWTs. We will use that tool to create a token for testing.

![JWT.io](https://user-images.githubusercontent.com/1342803/44101613-ce328e04-9fb5-11e8-9aed-2d9900d0c40c.png)

### Header

The header is mainly used to specify which algorithm was used to generate the token's signature. This is used by the accepting app to verify the token's authenticity.

Here is the raw JSON data for our header:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

This specifies the HMAC SHA-256 signing algorithm and that our token is indeed a JWT.

### Payload

The payload is where you store information to identify the authenticated user. You can store any data you want here, but be careful not to store too much as some web browsers limit HTTP header sizes. 

The payload is also where you store _claims_. Claims are standardized key / value pairs that many JWT implementations can recognize and act on automatically. A commonly used claim is _Expiration Time_ which stores the token's expiration date as a unix timestamp at key `"exp"`. See a full list of supported claims in [RFC 7519 &sect; 4.1](https://tools.ietf.org/html/rfc7519#section-4.1).

To keep things simple, we will just include our user's identifier and name in the payload:

```json
{
  "id": 42,
  "name": "Vapor Developer"
}
```

### Secret

Last but not least is the secret key used to sign and verify the JWT. For this example, we are using the `HS256` algorithm (specified in the JWT header). HMAC algorithms use a single secret key for both signing and verifying.

To keep things simple, we will use the following string as our key:

```
secret
```

Other algorithms, like RSA, use asymmetric (public and private) keys. With these types of algorithms, only the _private_ key is able to create (sign) JWTs. Both the _public_ and _private_ keys can verify JWTs. This allows for an added layer of security as you can distribute the public key to services that should only be able to verify tokens, not create them.

### Serialized

Finally, here is our fully serialized token. This will be sent via the bearer authorization header. 

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NDIsIm5hbWUiOiJWYXBvciBEZXZlbG9wZXIifQ.__Dm_tr1Ky2VYhZNoN6XpEkaRHjtRgaM6HdgDFcc9PM
```

Each segment is separated by a `.`. The overall structure of the token is the following:

```
<header>.<payload>.<signature>
```

Note that the header and payload segments are simply base64-url encoded JSON. It is important to remember that all information your store in a normal JWT is publically readable.


## Parse

Let's take a look at how to parse and verify incoming JWTs. 

### Payload

First, we need to create a `Codable` type that represents our payload. This should also conform to [`JWTPayload`](https://api.vapor.codes/jwt/latest/JWT/Protocols/JWTPayload.html).

```swift
struct User: JWTPayload {
    var id: Int
    var name: String

    func verify(using signer: JWTSigner) throws {
        // nothing to verify
    }
}
```

Since our simple payload does not include any claims, we can leave the `verify(using:)` method empty for now.

### Route

Now that our payload type is ready, we can parse and verify an incoming JWT.

```swift
import JWT
import Vapor

router.get("hello") { req -> String in
    // fetches the token from `Authorization: Bearer <token>` header
    guard let bearer = req.http.headers.bearerAuthorization else {
        throw Abort(.unauthorized)
    }

    // parse JWT from token string, using HS-256 signer
    let jwt = try JWT<User>(from: bearer.token, verifiedUsing: .hs256(key: "secret"))
    return "Hello, \(jwt.payload.name)!"
}
```

This snippet creates a new route at `GET /hello`. The first part of the route handler fetches the `<token>` value from the bearer authorization header. The second part uses the [`JWT`](https://api.vapor.codes/jwt/latest/JWT/Structs/JWT.html) struct to parse the token using an `HS256` signer.

Once the JWT is parsed, we access the [`payload`](https://api.vapor.codes/jwt/latest/JWT/Structs/JWT.html#/s:3JWTAAV7payloadxvp) property which contains an instance of our `User` type. We then access the `name` property to say hello!

Run the following request and check the output:

```http
GET /hello HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NDIsIm5hbWUiOiJWYXBvciBEZXZlbG9wZXIifQ.__Dm_tr1Ky2VYhZNoN6XpEkaRHjtRgaM6HdgDFcc9PM
Content-Length: 0
```

You should see the following response:

```http
HTTP/1.1 200 OK
Content-Length: 23
Hello, Vapor Developer!
```

## Serialize

Let's take a look at how to create and sign a JWT.

### Payload

First, we need to create a `Codable` type that represents our payload. This should also conform to [`JWTPayload`](https://api.vapor.codes/jwt/latest/JWT/Protocols/JWTPayload.html).

```swift
struct User: JWTPayload {
    var id: Int
    var name: String

    func verify(using signer: JWTSigner) throws {
        // nothing to verify
    }
}
```

Since our simple payload does not include any claims, we can leave the `verify(using:)` method empty for now.

### Route

Now that our payload type is ready, we can generate a JWT.

```swift
router.post("login") { req -> String in
    // create payload
    let user = User(id: 42, name: "Vapor Developer")

    // create JWT and sign
    let data = try JWT(payload: user).sign(using: .hs256(key: "secret"))
    return String(data: data, encoding: .utf8) ?? ""
}
```

This snippet creates a new route at `POST /login`. The first part of the route handler creates an instance of our `User` payload type. The second part creates an instance of `JWT` using our payload, and calls the [`sign(using:)`](https://api.vapor.codes/jwt/latest/JWT/Structs/JWT.html#/s:3JWTAAV4sign10Foundation4DataVAA9JWTSignerC5using_tKF) method. This method returns `Data`, which we convert to a `String`.

If you visit this route, you should get the following output:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NDIsIm5hbWUiOiJWYXBvciBEZXZlbG9wZXIifQ.__Dm_tr1Ky2VYhZNoN6XpEkaRHjtRgaM6HdgDFcc9PM
```

If you plug that JWT into [jwt.io](https://jwt.io) and enter the secret (`secret`), you should see the encoded data and a message "Signature Verified".



