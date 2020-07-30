# JWT


JSON Web Token (JWT) is an open standard ([RFC 7519](https://tools.ietf.org/html/rfc7519)) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object. This information can be verified and trusted because it is digitally signed. JWTs can be signed using a secret (with the HMAC algorithm) or a public/private key pair using RSA or ECDSA.

## Getting Started

The first step to using JWT is adding the dependency to your [Package.swift](spm.md#package-manifest).

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
		 // Other dependencies...
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Other dependencies...
            .product(name: "JWT", package: "jwt")
        ]),
        // Other targets...
    ]
)
```

If you edit the manifest directly inside Xcode, it will automatically pick up the changes and fetch the new dependency when the file is saved. Otherwise, run `swift package resolve` to fetch the new dependency.

### Configuration

The JWT module adds a new property `jwt` to `Application` that you can use to configure how your app handles JWTs. To sign or verify JWTs, you will need to configure a signer. The simplest signing algorithm is `HS256` or HMAC with SHA-256. 

```swift
import JWT

// Add HMAC with SHA-256 signer.
app.jwt.signers.use(.hs256(key: "secret"))
```

The `HS256` signer requires a key to initialize. Unlike other signers, this single key is used for both signing _and_ verifying tokens. Learn more about the available [algorithms](#algorithms) below.

### Payload

Let's try to verify the following example JWT.

```swift
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

You can inspect the contents of this token by visiting [jwt.io](https://jwt.io) and pasting the token in the debugger. Set the key in the "Verify Signature" section to `secret`. 

We need to create a struct conforming to `JWTPayload` that represents the JWT's structure. We'll use JWT's included [claims](#claims) to handle common fields like `sub` and `exp`. 

```swift
// JWT payload structure.
struct TestPayload: JWTPayload {
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim

    // The "exp" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim

    // Custom data.
    // If true, the user is an admin.
    var isAdmin: Bool

    // Run any additional verification logic beyond
    // signature verification here.
    // Since we have an ExpirationClaim, we will
    // call its verify method.
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
```

### Verify

Now that we have a `JWTPayload`, we can attach it to a request and use the JWT package to fetch and verify it. Add the following route to your project. 

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req -> HTTPStatus in
    let payload = try req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

The `req.jwt.verify` helper will check the `Authorization` header for a bearer token. If one exists, it will parse the JWT and verify its signature and claims. If any of these steps fail, a _401 Unauthorized_ error will be thrown.

Test the route by sending the following HTTP request. 

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

If everything worked, a _200 OK_ response will be returned and the payload printed:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

### Signing

This package can also _generate_ JWTs, also known as signing. To demonstrate this, let's use the `TestPayload` from the previous section. Add the following route to your project.

```swift
// Generate and return a new JWT.
app.post("login") { req -> [String: String] in
    // Create a new instance of our JWTPayload
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    // Return the signed JWT
    return try [
        "token": req.jwt.sign(payload)
    ]
}
```

The `req.jwt.sign` helper will use the default configured signer to serialize and sign the `JWTPayload`. The encoded JWT is returned as a `String`. 

Test the route by sending the following HTTP request. 

```http
POST /login HTTP/1.1
```

You should see the newly generated token returned in a _200 OK_ response.

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```
