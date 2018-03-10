# JSON Web Token

JSON Web Token is a library containing all JSON Web Token related APIs.

### What is JWT?

JWT is a standard for managing client tokens. Tokens are a form of identification and proof to the server. JWT is cryptographically signed, so it is not possible to falsify the validity of a JWT unless any of the following conditions is met:

- A broken algorithm was used (such as MD5)
- A weak signing key was used and brute-forced
- The signing key used was leaked out to a third party

Please note that any private/secret data **must not** be stored inside a JSON Web Token since they're publically readable. They are **not** encrypted.


## With Vapor

This package is included with Vapor by default, just add:

```swift
import JWT
```

## Without Vapor

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/jwt.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["JWT", ... ])
    ]
)
```

If this is your first time adding a dependency, you should read our introduction to [Package.swift](../getting-started/spm.md).

Use `import JWT` to access JSON Web Token's APIs.

## Signed JSON Web Tokens

JSON Web Signatures are a Base64 encoded token with a signature for verification.

This means signatures can be read by the client and **must not** contain sensitive data such as passwords.

It can be used as an authentication token or "proof" by the client.

It does not need to be stored on the server and can be verified by any server that knows the key used for signing.

### Creating a token

Creating a token is as simple as creating a Codable struct.

```swift
struct AuthorizationToken : JWTPayload {
    // Predefined claim(s)
    let iat: IssuedAtClaim
    let exp: ExpirationClaim

    // Custom claim(s)
    let username: String

    init(username: String, expirationDate: Date) {
        // now
        iat = IssuedAtClaim(value: Date())
        exp = ExpirationClaim(value: expirationDate)

        username = username
    }

    func verify() throws {
        // Verify that the Token is not expired
        try exp.verify()
    }
}
```

### Creating a signer

To create a signer you need a "key" of the type `Data`. This data will be used as the signing key.
This key should be randomly generated for security and should not be shared outside of the system.

```swift
let signer = JWTSigner.hs512(key: key)
```

### Sending a signed token with the client

To send a token to a client you need to sign it with a signer.

```swift
let encodedSignature = try jws.sign(using: signer) // Data
```

The signature is `Data` but can be easily initialized to a String.

```swift
guard let signature = String(data: encodedSignature, encoding: .utf8) else {
    // handle this error situation
}
```

Make sure you did `import Foundation` in this file.

### Decoding a token

When the client interacts with your website again, they'll have a token this time. This token needs to be decoded and verified first.

```swift
let signature: try JWT<AuthorizationToken>(from: encodedSignature, verifyingWith: signer)
```

The `signer` in this example is a `JWTSigner`.

To extract the `AuthorizationToken`, you access the `token.payload`.

```swift
let token: AuthorizationToken = signature.payload

print(token.username) // prints "Example Username"
```
