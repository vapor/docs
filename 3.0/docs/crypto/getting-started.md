# Using Crypto

Crypto is a library containing all common APIs related to cryptography and security.

This project does **not** support TLS. For that, please see [the TLS package](../tls/getting-started.md).

## With Vapor

This package is included with Vapor by default, just add:

```swift
import Crypto
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
        .package(url: "https://github.com/vapor/crypto.git", .upToNextMajor(from: "x.0.0")),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Crypto", ... ])
    ]
)
```

Use `import Crypto` to access Crypto's APIs.

## Available hashes

Hashes are a one-directional encryption that is commonly used for validating data or one-way encrypting data such as passwords.

### Hashing blobs of data

Every `Hash` has a static method called `hash` that can be used for hashing the entire contents of `Data`, `ByteBuffer` or `String`.

The result is `Data` containing the resulting hash. The hash's length is according to spec and defined in the static variable `digestSize`.

```swift
// MD5 with `Data`
let fileData = Data()
let fileMD5 = MD5.hash(fileData)

// SHA1 with `ByteBuffer`
let fileBuffer: ByteBuffer = ...
let fileSHA1 = SHA1.hash(fileBuffer)

// SHA2 variants with String
let staticUnsafeToken: String = "rsadd14ndmasidfm12i4j"

let tokenHashSHA224 = SHA224.hash(staticUnsafeToken)
let tokenHashSHA256 = SHA256.hash(staticUnsafeToken)
let tokenHashSHA384 = SHA384.hash(staticUnsafeToken)
let tokenHashSHA512 = SHA512.hash(staticUnsafeToken)
```

### Incremental hashes (manual)

To incrementally process hashes you can create an instance of the Hash. This will set up a context.

All hash context initializers are empty:

```swift
// Create an MD5 context
let md5Context = MD5()
```

To process a single chunk of data, you can call the `update` function on a context using any `Sequence` of `UInt8`. That means `Array`, `Data` and `ByteBuffer` work alongside any other sequence of bytes.

```swift
md5Context.update(data)
```

The data data need not be a specific length. Any length works.

When you need the result, you can call `md5Context.finalize()`. This will finish calculating the hash by appending the standard `1` bit, padding and message bit length.

You can optionally provide a last set of data to `finalize()`. After calling `finalize()`, do not update the hash if you want a valid result.

The context can then be accessed to extract the resulting Hash.

```swift
let hash: Data = md5Context.hash
```

## Message authentication

Message authentication is used for verifying message authenticity and validity.

Common use cases are JSON Web Tokens.

For message authentication, Vapor only supports HMAC.

To use HMAC you first need to select the used hashing algorithm for authentication using generics.

```swift
let hash = HMAC<SHA224>.authenticate(message, withKey: authenticationKey)
```

## Password hashing

Password management is critical for good user security and doesn't need to cost a lot of effort. No software is perfect. Even if your software is perfect, other software on the same server likely isn't. Good password encryption security prevents users' passwords from leaking out in case of a hypothetical future data breach.

For password hashing Vapor supports PBKDF2 and BCrypt.

We recommend using BCrypt over PBKDF2 for almost all scenarios. Whilst PBKDF2 is a proven standard, it's much more easily brute-forced than BCrypt and is less future-proof.

### BCrypt

BCrypt is an algorithm specifically designed for password hashing. It's easy to store and verify.

Unlike PBKDF2 you don't need to generate and store a salt, that's part of the BCrypt hashing and verification process.

The output is a combination of the BCrypt "cost" factor, salt and resulting hash. Meaning that the derived output contains all information necessary for verification, simplifying the database access.

```swift
let result: Data = try BCrypt.make(message: "MyPassword")

guard try BCrypt.verify(message: "MyPassword", matches: result) else {
    // Password invalid
}
```

The default cost factor is `12`, based on the official recommendations.

BCrypt always outputs valid ASCII/UTF-8 for the resulting hash.

This means you can convert the output `Data` to a `String` as such:

```swift
guard let string = String(bytes: result, encoding: .utf8) else {
    // This must never trigger
}
```

### PBKDF2

PBKDF2 can be paired up with any hashing algorithm and is simple to implement. For PBKDF2 you also select the Hash using generics.

In the following example:

- `password` is either a `String` or `Data`
- Iterations defaulted to `10_000` iterations
- The keySize is equivalent to 1 hash's length, in this case SHA256

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

When you're storing the PBKDF2 results you must also store the Salt. Without the original salt, iteration count and other parameters you cannot reproduce the same results for validation or authentication.

## Random

Crypto has two primary random number generators.

OSRandom generates random numbers by calling the operating system's random number generator.

URandom generates random numbers by reading from `/dev/urandom`.

First, create an instance of the preferred random number generator:

```swift
let random = OSRandom()
```

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
let uint = try random.makeUInt() // UInt
```

Random buffers of data are useful when, for example, generating tokens or other unique strings/blobs.

To generate a buffer of random data:

```swift
// generates 20 random bytes
let data: Data = random.data(count: 20)
```
