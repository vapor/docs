# JWT


JSON Web Token (JWT) is an open standard ([RFC 7519](https://tools.ietf.org/html/rfc7519)) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object. This information can be verified and trusted because it is digitally signed. JWTs can be signed using a secret (with the HMAC algorithm) or a public/private key pair using RSA or ECDSA.

## Getting Started

The first step to using JWT is adding the dependency to your [Package.swift](../getting-started/spm.md#package-manifest).

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

The JWT module adds a new property `jwt` to `Application` that is used for configuration. To sign or verify JWTs, you will need to add a signer. The simplest signing algorithm is `HS256` or HMAC with SHA-256. 

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

Now that we have a `JWTPayload`, we can attach the JWT above to a request and use `req.jwt` to fetch and verify it. Add the following route to your project. 

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

## Authentication

For more information on using JWT with Vapor's authentication API, visit [Authentication &rarr; JWT](authentication.md#jwt).

## Algorithms

Vapor's JWT API supports verifying and signing tokens using the following algorithms.

### HMAC

HMAC is the simplest JWT signing algorithm. It uses a single key that can both sign and verify tokens. The key can be any length.

- `hs256`: HMAC with SHA-256
- `hs384`: HMAC with SHA-384
- `hs512`: HMAC with SHA-512

```swift
// Add HMAC with SHA-256 signer.
app.jwt.signers.use(.hs256(key: "secret"))
```

### RSA

RSA is the most commonly used JWT signing algorithm. It supports distinct public and private keys. This means that a public key can be distributed for verifying JWTs are authentic while the private key that generates them is kept secret.

To create an RSA signer, first initialize an `RSAKey`. This can be done by passing in the components.

```swift
// Initialize an RSA key with components.
let key = RSAKey(
    modulus: "...",
    exponent: "...",
    // Only included in private keys.
    privateExponent: "..."
)
```

You can also choose to load a PEM file:

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialize an RSA key with public pem.
let key = RSAKey.public(pem: rsaPublicKey)
```

Use `.private` for loading private RSA PEM keys. These start with:

```
-----BEGIN RSA PRIVATE KEY-----
```

Once you have the RSAKey, you can use it to create an RSA signer.

- `rs256`: RSA with SHA-256
- `rs384`: RSA with SHA-384
- `rs512`: RSA with SHA-512

```swift
// Add RSA with SHA-256 signer.
try app.jwt.signers.use(.rs256(key: .public(pem: rsaPublicKey)))
```

### ECDSA

ECDSA is a more modern algorithm that is similar to RSA. It is considered to be more secure for a given key length than RSA[^1]. However, you should do your own research before deciding. 

[^1]: https://sectigostore.com/blog/ecdsa-vs-rsa-everything-you-need-to-know/

Like RSA, you can load ECDSA keys using PEM files: 

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialize an ECDSA key with public PEM.
let key = ECDSAKey.public(pem: ecdsaPublicKey)
```

Use `.private` for loading private ECDSA PEM keys. These start with:

```
-----BEGIN PRIVATE KEY-----
```

You can also generate random ECDSA using the `generate()` method. This is useful for testing.

```swift
let key = try ECDSAKey.generate()
```

Once you have the ECDSAKey, you can use it to create an ECDSA signer.

- `es256`: ECDSA with SHA-256
- `es384`: ECDSA with SHA-384
- `es512`: ECDSA with SHA-512

```swift
// Add ECDSA with SHA-256 signer.
try app.jwt.signers.use(.es256(key: .public(pem: ecdsaPublicKey)))
```

### Key Identifier (kid)

If you are using multiple algorithms, you can use key identifiers (`kid`s) to differentiate them. When configuring an algorithm, pass the `kid` parameter. 

```swift
// Add HMAC with SHA-256 signer named "a".
app.jwt.signers.use(.hs256(key: "foo"), kid: "a")
// Add HMAC with SHA-256 signer named "b".
app.jwt.signers.use(.hs256(key: "bar"), kid: "b")
```

When signing JWTs, pass the `kid` parameter for the desired signer.

```swift
// Sign using signer "a"
req.jwt.sign(payload, kid: "a")
```

This will automatically include the signer's name in the JWT header's `"kid"` field. When verifying the JWT, this field will be used to look up the appropriate signer. 

```swift
// Verify using signer specified by "kid" header.
// If no "kid" header is present, default signer will be used.
let payload = try req.jwt.verify(as: TestPayload.self)
```

Since [JWKs](#jwk) already contain `kid` values, you do not need to specify them during configuration.

```swift
// JWKs already contain the "kid" field.
let jwk: JWK = ...
app.jwt.signers.use(jwk: jwk)
```

## Claims

Vapor's JWT package includes several helpers for implementing common [JWT claims](https://tools.ietf.org/html/rfc7519#section-4.1). 

|Claim|Type|Verify Method|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

All claims should be verified in the `JWTPayload.verify` method. If the claim has a special verify method, you can use that. Otherwise, access the value of the claim using `value` and check that it is valid.

## JWK

A JSON Web Key (JWK) is a JavaScript Object Notation (JSON) data structure that represents a cryptographic key ([RFC7517](https://tools.ietf.org/html/rfc7517)). These are commonly used to supply clients with keys for verifying JWTs.

For example, Apple hosts their _Sign in with Apple_ JWKS at the following URL.

```http
GET https://appleid.apple.com/auth/keys
```

You can add this JSON Web Key Set (JWKS) to your `JWTSigners`. 

```swift
import JWT
import Vapor

// Download the JWKS.
// This could be done asynchronously if needed.
let jwksData = try Data(
    contentsOf: URL(string: "https://appleid.apple.com/auth/keys")!
)

// Decode the downloaded JSON.
let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)

// Create signers and add JWKS.
try app.jwt.signers.use(jwks: jwks)
```

You can now pass JWTs from Apple to the `verify` method. The key identifier (`kid`) in the JWT header will be used to automatically select the correct key for verification.

As of writing, JWK only supports RSA keys. Additionally, JWT issuers may rotate their JWKS meaning you need to re-download occasionally. See Vapor's supported JWT [Vendors](#vendors) list below for APIs that do this automatically.

## Vendors

Vapor provides APIs for handling JWTs from the popular issuers below.

### Apple

First, configure your Apple application identifier.

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

Then, use the `req.jwt.apple` helper to fetch and verify an Apple JWT. 

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.apple.verify().map { token in
        print(token) // AppleIdentityToken
        return .ok
    }
}

// Or

app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

First, configure your Google application identifier and G Suite domain name.

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

Then, use the `req.jwt.google` helper to fetch and verify a Google JWT. 

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.google.verify().map { token in
        print(token) // GoogleIdentityToken
        return .ok
    }
}

// or

app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

First, configure your Microsoft application identifier.

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

Then, use the `req.jwt.microsoft` helper to fetch and verify a Microsoft JWT. 

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req -> EventLoopFuture<HTTPStatus> in
    req.jwt.microsoft.verify().map { token in
        print(token) // MicrosoftIdentityToken
        return .ok
    }
}

// Or

app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
