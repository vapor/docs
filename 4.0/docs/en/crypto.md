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

## TOTP

Coming soon.

