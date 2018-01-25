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

Hashes are a one-directional encryption that is commonly used for validating files or one-way securing data such as passwords.

Crypto currently supports a few hashes.

- MD5
- SHA1
- SHA2 (all variants)

MD5 and SHA1 are generally used for file validation or legacy (weak) passwords. They're performant and lightweight.

Every Hash type has a set of helpers that you can use.

### Hashing blobs of data

Every `Hash` has a static method called `hash` that can be used for hashing the entire contents of `Foundation.Data`, `ByteBuffer` or `String`.

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

When you need the result, you can call `md5Context.finalize()`. This will finish calculating the hash by appending the standard `1` bit, padding and message bitlength.

You can optionally provide a last set of data to `finalize()`.

After calling `finalize()`, do not update the hash if you want correct results.

### Fetching the results

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
