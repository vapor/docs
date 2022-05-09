# Passwords

Vapor includes a password hashing API to help you store and verify passwords securely. This API is configurable based on environment and supports asynchronous hashing.

## Configuration

To configure the Application's password hasher, use `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

To use Vapor's [Bcrypt API](crypto.md#bcrypt) for password hashing, specify `.bcrypt`. This is the default.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt will use a cost of 12 unless otherwise specified. You can configure this by passing the `cost` parameter.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vapor includes an insecure password hasher that stores and verifies passwords as plaintext. This should not be used in production but can be useful for testing.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hashing

To hash passwords, use the `password` helper available on `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Password digests can be verified against the plaintext password using the `verify` method.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

The same API is available on `Application` for use during boot.

```swift
let digest = try app.password.hash("vapor")
```

### Async 

Password hashing algorithms are designed to be slow and CPU intensive. Because of this, you may want to avoid blocking the event loop while hashing passwords. Vapor provides an asynchronous password hashing API that dispatches hashing to a background thread pool. To use the asynchronous API, use the `async` property on a password hasher.

```swift
req.password.async.hash("vapor").map { digest in
    // Handle digest.
}

// or

let digest = try await req.password.async.hash("vapor")
```

Verifying digests works similarly:

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Handle result.
}

// or

let result = try await req.password.async.verify("vapor", created: digest)
```

Calculating hashes on background threads can free your application's event loops up to handle more incoming requests.

