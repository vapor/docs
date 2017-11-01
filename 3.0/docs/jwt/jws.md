# JWS (JSON Web Signature) tokens

JSON Web Signatures are a Base64 encoded token with a signature for verification.

This means signatures can be read by the client and **must not** contain sensitive data such as passwords.

It can be used as an authentication token or "proof" by the client.

It does not need to be stored on the server and can be verified by any server that knows the key used for signing.

## Creating a token

Creating a token is as simple as creating a Codable struct.

```swift
struct AuthorizationToken : Codable {
  let authenticatedUsername: String
}
```

## Sending a signed token with the client

To send a token to the client, you need to sign it. Signing is done using a "secret". Secrets are a static key that stays the same across server reboots and is usually put inside a configuration file.

Secrets _should_ be randomly generated. Longer secrets and less predictable are better, there is no limit.

Once a secret is available in the application you can sign your tokens.

To sign your token, you need to select an algorithm. We support `hs256`, `hs384` and `hs512`.

```swift
let header = JWT.Header.hs512()
```

For this example, the following token/payload is used:

```swift
let token = AuthorizationToken(authenticatedUsername: "Example Username")
```

Then, create a signature.

```swift
let secret: Data = ... // your secret

let jws = JSONWebSignature(headers: [header], payload: token, secret: secret)
```

Secrets are expected to be a `Foundation.Data`. If your secret is a `String`, convert it using `Data(stringSecret.utf8)`.

To receive the signature as a String (for in a Cookie or JSON response) you can use `signedString`.

```swift
let encodedSignature: String = try jws.signedString()
```

If you want binary data instead, use `sign`:

```swift
let encodedSignature: Data = try jws.sign()
```

## Decoding a token

When the client interacts with your website again, they'll have a token this time. This token needs to be decoded and verified first.

```swift
let signature: try JSONWebSignature<AuthorizationToken>(from: encodedSignature, verifyingWith: secret)
```

The `signature` in this example is a `Data` or `String` containing the encoded signature.

The secret is the same secret we used in the above example for signing.

If the message has been tampered with, the token will not be initialized and an error will be thrown instead.

To extract the `AuthorizationToken`, you access the `token.payload`.

```swift
let token: AuthorizationToken = signature.payload

print(token.username) // prints "Example Username"
```
