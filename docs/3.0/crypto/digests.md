# Message Digests

Cryptographic hash functions (also known as message digest algorithms) convert data of arbitrary size to a fixed-size digest. These are most often used for generating checksums or identifiers for large data blobs.

Read more about [Cryptographic hash functions](https://en.wikipedia.org/wiki/Cryptographic_hash_function) on Wikipedia.

## Hash

Use the global convenience variables to create hashes using common algorithms.

```swift
import Crypto

let digest = try SHA1.hash("hello")
print(digest.hexEncodedString()) // aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
```

See the Crypto module's [global variables](https://api.vapor.codes/crypto/latest/Crypto/Global%20Variables.html#/Digests) for a list of all available hash algorithms.

### Streaming

You can create a [`Digest`](https://api.vapor.codes/crypto/latest/Crypto/Classes/Digest.html) manually and use its instance methods to create a hash for one or more data chunks.

```swift
var sha256 = try Digest(algorithm: .sha256)
try sha256.reset()
try sha256.update(data: "hello")
try sha256.update(data: "world")
let digest = try sha256.finish()
print(digest) /// Data
```

## BCrypt

BCrypt is a popular hashing algorithm that has configurable complexity and handles salting automatically.

### Hash

Use the `hash(_:cost:salt:)` method to create BCrypt hashes.

```swift
let digest = try BCrypt.hash("vapor", cost: 4)
print(digest) /// data
```

Increasing the `cost` value will make hashing and verification take longer.

### Verify

Use the `verify(_:created:)` method to verify that a BCrypt hash was created by a given plaintext input.

```swift
let hash = try BCrypt.hash("vapor", cost: 4)
try BCrypt.verify("vapor", created: hash) // true
try BCrypt.verify("foo", created: hash) // false
```

## HMAC

HMAC is an algorithm for creating _keyed_ hashes. HMAC will generate different hashes for the same input if different keys are used.

```swift
let digest = try HMAC.SHA1.authenticate("vapor", key: "secret") 
print(digest.hexEncodedString()) // digest
```

See the [`HMAC`](https://api.vapor.codes/crypto/latest/Crypto/Classes/HMAC.html) class for a list of all available hash algorithms.

### Streaming

HMAC hashes can also be streamed. The API is identical to [hash streaming](#streaming).
