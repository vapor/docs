# Password hashing

For password hashing Vapor supports PBKDF2 and BCrypt.

## PBKDF2

PBKDF2 is an algorithm that is almost always (and in Vapor, exclusively) used with HMAC for message authentication.

PBKDF2 can be paired up with any hashing algorithm and is simple to implement. We recommend using BCrypt over PBKDF2 for almost all scenarios. But we still recommend PBKDF2 above any normal hashing function.

For PBKDF2 you also select the Hash using generics.

### Deriving a key

In the following example:

- `password` is either a `String` or `Data`
- The `salt` is `Data`
- Iterations is defaulting to `10_000` iterations
- The keySize is equivalent to 1 hash's length.

```swift
// Generate a random salt
let salt: Data = ...

let hash = try PBKDF2<SHA256>.derive(fromPassword: password, salt: salt)
```

You can optionally configure PBKDF2 to use a different iteration count and output keysize.

```swift
// Iterates 20'000 times and outputs 100 bytes
let hash = try PBKDF2<SHA256>.derive(fromPassword: password, salt: salt, iterating: 20_000, derivedKeyLength: 100)
```

## BCrypt - TODO
