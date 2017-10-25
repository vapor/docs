# Password hashing

Password management is critical for good user security and doesn't need to cost a lot of effort. No software is perfect. Even if your software is perfect, other software on the same server likely isn't. Good password encryption security prevents users' passwords from leaking out in case of a hypothetical future data breach.

For password hashing Vapor supports PBKDF2 and BCrypt.

We recommend using BCrypt over PBKDF2 for almost all scenarios. Whilst PBKDF2 is a proven standard, it's much more easily brute-forced than BCrypt and is less future-proof.

## BCrypt

BCrypt is an algorithm specifically designed for password hashing. It's easy to store and verify.

### Deriving a key

Unlike PBKDF2 you don't need to generate and store a salt, that's part of the BCrypt hashing and verification process.

The output is a combination of the BCrypt "cost" factor, salt and resulting hash. Meaning that the derived output contains all information necessary for verification, simplifying the database access.

```swift
let result: Data = try BCrypt.make(message: "MyPassword")

guard try BCrypt.verify(message: "MyPassword", matches: result) else {
    fatalError("This never triggers, since the verification process will always be successful for the same password and conditions")
}
```

The default cost factor is `12`, based on the official recommendations.

### Storing the derived key as a String

BCrypt always outputs valid ASCII/UTF-8 for the resulting hash.

This means you can convert the output `Data` to a `String` as such:

```swift
guard let string = String(bytes: result, encoding: .utf8) else {
    // This must never trigger
}
```

## PBKDF2

PBKDF2 is an algorithm that is almost always (and in Vapor, exclusively) used with HMAC for message authentication.

PBKDF2 can be paired up with any hashing algorithm and is simple to implement. PBKDF2 is used all over the world through the WPA2 standard, securing WiFi connections. But we still recommend PBKDF2 above any normal hashing function.

For PBKDF2 you also select the Hash using generics.

### Deriving a key

In the following example:

- `password` is either a `String` or `Data`
- The `salt` is `Data`
- Iterations is defaulted to `10_000` iterations
- The keySize is equivalent to 1 hash's length.

```swift
// Generate a random salt
let salt: Data = OSRandom().data(count: 32)

let hash = try PBKDF2<SHA256>.derive(fromPassword: password, salt: salt)
```

You can optionally configure PBKDF2 to use a different iteration count and output keysize.

```swift
// Iterates 20'000 times and outputs 100 bytes
let hash = try PBKDF2<SHA256>.derive(fromPassword: password, salt: salt, iterating: 20_000, derivedKeyLength: 100)
```

### Storing the results

When you're storing the PBKDF2 results, be sure to also store the Salt. Without the original salt, iteration count and other parameters you cannot reproduce the same hash for validation or authentication.
