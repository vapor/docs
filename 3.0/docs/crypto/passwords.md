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
    // Password invalid
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

You can optionally configure PBKDF2 to use a different iteration count and output key size.

```swift
// Iterates 20'000 times and outputs 100 bytes
let hash = try PBKDF2<SHA256>.derive(fromPassword: password, salt: salt, iterating: 20_000, derivedKeyLength: 100)
```

### Storing the results

When you're storing the PBKDF2 results, be sure to also store the Salt. Without the original salt, iteration count and other parameters you cannot reproduce the same hash for validation or authentication.

## Random

Crypto has two primary random number generators.

OSRandom generates random numbers by calling the operating system's random number generator.

URandom generates random numbers by reading from `/dev/urandom`.

### Accessing random numbers

First, create an instance of the preferred random number generator:

```swift
let random = OSRandom()
```

or

```swift
let random = try URandom()
```

### Reading integers

For every Swift integer a random number function exists.

```swift
let int8 = try random.makeInt8() // Int8
let uint8 = try random.makeUInt8() // UInt8
let int16 = try random.makeInt16() // Int16
let uint16 = try random.makeUInt16() // UInt16
let int32 = try random.makeInt32() // Int32
let uint32 = try random.makeUInt32() // UInt32
let int64 = try random.makeInt64() // Int64
let uint64 = try random.makeUInt64() // UInt64
let int = try random.makeInt() // Int
let uint: = try random.makeUInt() // UInt
```

### Reading random data

Random buffers of data are useful when, for example, generating tokens or other unique strings/blobs.

To generate a buffer of random data:

```swift
// generates 20 random bytes
let data: Data = random.data(count: 20)
```
