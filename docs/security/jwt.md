# JWT

JSON Web Token (JWT) is an open standard ([RFC 7519](https://tools.ietf.org/html/rfc7519)) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object. This information can be verified and trusted because it is digitally signed.
JWTs are particularly useful in web applications, where they are commonly used for stateless authentication/authorization and information exchange. You can read more about the theory behind JWTs in the spec linked above or on [jwt.io](https://jwt.io/introduction).

Vapor provides first-class support for JWTs through the `JWT` module. This module is built on top of the `JWTKit` library, which is a Swift implementation of the JWT standard based on [SwiftCrypto](https://github.com/apple/swift-crypto). JWTKit provides signers and verifiers for a variety of algorithms, including HMAC, ECDSA, EdDSA, and RSA.

## Getting Started

The first step to using JWTs in your Vapor application is to add the `JWT` dependency to your project's `Package.swift` file: 

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Other dependencies...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0-rc"),
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

### Configuration

After adding the dependency, you can start using the `JWT` module in your application. The JWT module adds a new `jwt` property to `Application` that is used for configuration, of which the internals are provided by the [JWTKit](https://github.com/vapor/jwt-kit) library.

#### Key Collection
The `jwt` object comes with a `keys` property, which is an instance of JWTKit's `JWTKeyCollection`. This collection is used to store and manage the keys used to sign and verify JWTs. The `JWTKeyCollection` is an `actor`, which means that all operations on the collection are serialized and thread-safe.

To sign or verify JWTs, you will need to add a key to the collection. This is usually done in your `configure.swift` file:

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

This adds an HMAC key with SHA-256 as the digest algorithm to the keychain, or HS256 in JWA notation. Check out the [algorithms](#algorithms) section below for more information on the available algorithms.

!!! note 
    Be sure to replace `"secret"` with an actual secret key. This key should be kept secure, ideally in a configuration file or environment variable.

### Signing

The added key can then be used to sign JWTs. To do this,
you first of all need _something_ to sign, namely a 'payload'. 
This payload is simply a JSON object containing the data you want to transmit. You can create your custom payload by conforming your structure to the `JWTPayload` protocol:

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
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

Signing the payload is done by calling the `sign` method on the `JWT` module, for example inside of a route handler:

```swift
app.post("login") { req async throws -> [String: String]
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    return try await ["token": req.jwt.sign(payload)]
}
```

When a request is made to this endpoint, it will return the signed JWT as a `String` in the response body, and if everything went according to plan, you'll see something like this:

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

You can decode and verify this token using the [`jwt.io` debugger](https://jwt.io/#debugger). The debugger will show you the payload (which should be the data you specified earlier) and header of the JWT, and you can verify the signature using the secret key you used to sign the JWT.

### Verifying

When a token is instead sent _to_ your application, you can verify the authenticity of the token by calling the `verify` method on the `JWT` module:

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

The `req.jwt.verify` helper will check the `Authorization` header for a bearer token. If one exists, it will parse the JWT and verify its signature and claims. If any of these steps fail, a 401 Unauthorized error will be thrown.
Test the route by sending the following HTTP request:

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

If everything worked, a `200 OK` response will be returned and the payload printed:

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

The whole authentication flow can be found at [Authentication &rarr; JWT](authentication.md#jwt).

## Algorithms

JWTs can be signed using a variety of algorithms. 
To add a key to the keychain, an overload of the `add` method is available for each of the following algorithms:

### HMAC

HMAC (Hash-based Message Authentication Code) is a symmetric algorithm that uses a secret key to sign and verify the JWT. Vapor supports the following HMAC algorithms:
- `HS256`: HMAC with SHA-256
- `HS384`: HMAC with SHA-384
- `HS384`: HMAC with SHA-384

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (Elliptic Curve Digital Signature Algorithm) is an asymmetric algorithm that uses a public/private key pair to sign and verify the JWT. It's reliance is based on the math around elliptic curves. Vapor supports the following ECDSA algorithms:
- `ES256`: ECDSA with a P-256 curve and SHA-256
- `ES384`: ECDSA with a P-384 curve and SHA-384
- `ES512`: ECDSA with a P-521 curve and SHA-512

All algorithms provide botha public key and a private key, such as `ES256PublicKey` and `ES256PrivateKey`. You can add ECDSA keys using the PEM format:

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialize an ECDSA key with public PEM.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

or generate random ones (useful for testing): 

```swift
let key = ES256PrivateKey()
```

To add the key to the keychain:

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (Edwards-curve Digital Signature Algorithm) is an asymmetric algorithm that uses a public/private key pair to sign and verify the JWT. It's similar to ECDSA in that both rely on the DSA algorithm, but EdDSA is based on the Edwards-curve, a different family of elliptic curves, and has slight performance improvements. It's however also newer and therefore less widely supported. Vapor only supports the `EdDSA` algorithm which uses the `Ed25519` curve.

You can create an EdDSA key using its (base-64 encoded `String`) coordinate, so `x` if it's a public key and `d` if it's a private key:

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

You can also generate random ones:

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

To add the key to the keychain:

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) is an asymmetric algorithm that uses a public/private key pair to sign and verify the JWT. 

!!! warning
    As you'll see, RSA keys are gated behind an `Insecure` namespace to discourage new users from using them. This is because RSA is considered less secure than ECDSA and EdDSA, and should only be used for compatibility reasons.
    If possible, use any of the other algorithms instead.

Vapor supports the following RSA algorithms:
- `RS256`: RSA with SHA-256
- `RS384`: RSA with SHA-384
- `RS512`: RSA with SHA-512

You can create an RSA key using its PEM format:

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
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

or usign its components:

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    The package does not support RSA keys smaller than 2048 bits.

Then you can add the key to the key collection:

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

In addition to the RSA-PKCS1v1.5 algorithm, Vapor also supports the RSA-PSS algorithm. PSS (Probabilistic Signature Scheme) is a more secure padding scheme for RSA signatures. It is recommended to use PSS over PKCS1v1.5 when possible.
The algorithm only differs in the signature phase, which means that the keys are the same as RSA, however, you need to specify the padding scheme when adding them to the key collection:

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## Key Identifier (kid)

When adding a key to the key collection, you can also specify a key identifier (kid). This is a unique identifier for the key that can be used to look up the key in the collection. 

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

If you don't specify a `kid`, the key will be assigned as the default key.

!!! note
    The default key will be overridden if you add another key without a `kid`.

When signing a JWT, you can specify the `kid` to use:

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

When verifying on the other hand, the `kid` is automatically extracted from the JWT header and used to look up the key in the collection. There's also a `iteratingKeys` parameter on the verify method that allows you to specify whether to iterate over all keys in the collection if the `kid` is not found.

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
A JSON Web Key (JWK) is a JSON data structure that represents a cryptographic key ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517)). These are commonly used to supply clients with keys for verifying JWTs.
For example, Apple hosts their Sign in with Apple JWKS at the following URL.

```http
GET https://appleid.apple.com/auth/keys
```

Vapor provides utilities to add JWKs to the key collection:

```swift
let privateKey = """
{
    "kty": "RSA",
    "d": "\(rsaPrivateExponent)",
    "e": "AQAB",
    "use": "sig",
    "kid": "1234",
    "alg": "RS256",
    "n": "\(rsaModulus)"
}
"""

let jwk = try JWK(json: privateKey)
try await app.jwt.keys.use(jwk: jwk)
```

This will add the JWK to the key collection, and you can use it to sign and verify JWTs as you would with any other key.

### JWKs

If you have multiple JWKs, you can add them just as well:

```swift
let json = """
{
    "keys": [
        {"kty": "RSA", "alg": "RS256", "kid": "a", "n": "\(rsaModulus)", "e": "AQAB"},
        {"kty": "RSA", "alg": "RS512", "kid": "b", "n": "\(rsaModulus)", "e": "AQAB"},
    ]
}
"""

try await app.jwt.keys.use(jwksJSON: json)
```

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
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
