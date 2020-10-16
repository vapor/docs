# Crypto

Vapor includes [SwiftCrypto](https://github.com/apple/swift-crypto/) which is a Linux-compatible port of Apple's CryptoKit library. Some additional crypto APIs are exposed for things SwiftCrypto does not have yet, like [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) and [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm). 

## SwiftCrypto

Swift's `Crypto` library implements Apple's CryptoKit API. As such, the [CryptoKit documentation](https://developer.apple.com/documentation/cryptokit) and the [WWDC talk](https://developer.apple.com/videos/play/wwdc2019/709) are great resources for learning the API.

These APIs will be available automatically when you import Vapor. 

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit includes support for:

- Hashing: `SHA512`, `SHA384`, `SHA256`
- Message Authentication Codes: `HMAC`
- Ciphers: `AES`, `ChaChaPoly`
- Public-Key Cryptography: `Curve25519`, `P521`, `P384`, `P256`
- Insecure hashing: `SHA1`, `MD5`

## Bcrypt

Bcrypt is a password hashing algorithm that uses a randomized salt to ensure hashing the same password multiple times doesn't result in the same digest.

Vapor provides a `Bcrypt` type for hashing and comparing passwords. 

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

Because Bcrypt uses a salt, password hashes cannot be compared directly. Both the plaintext password and the existing digest must be verified together. 

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// Password and digest match.
} else {
	// Wrong password.
}
```

Login with Bcrypt passwords can be implemented by first fetching the user's password digest from the database by email or username. The known digest can then be verified against the supplied plaintext password.

## OTP

Vapor supports both HOTP and TOTP one-time passwords. OTPs work with the SHA-1, SHA-256, and SHA-512 hash functions and can provide six, seven, or eight digits of output. An OTP provides authentication by generating a single-use human-readable password. To do so, parties first agree on a symmetric key, which must be kept private at all times to maintain the security of the generated passwords.

#### HOTP

HOTP is an OTP based on an HMAC signature. In addition to the symmetric key, both parties also agree on a counter, which is a number providing uniqueness for the password. After each generation attempt, the counter is increased.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// Or using the static generate function
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

A TOTP is a time-based variation of the HOTP. It works mostly the same, but instead of a simple counter, the current time is used to generate uniqueness. To compensate for the inevitable skew introduced by unsynchronized clocks, network latency, user delay, and other confounding factors, a generated TOTP code remains valid over a specified time interval (most commonly, 30 seconds).
```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// Or using the static generate function
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Range
OTPs are very useful for providing leeway in validation and out of sync counters. Both OTP implementations have the ability to generate an OTP with a margin for error.
```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// Generate a window of correct counters
let codes = hotp.generate(counter: 25, range: 2)
```
The example above allows for a margin of 2, which means the HOTP will be calculated for the counter values `23 ... 27`, and all of these codes will be returned. 

!!! warning
    Note: The larger the error margin used, the more time and freedom an attacker has to act, decreasing the security of the algorithm.
