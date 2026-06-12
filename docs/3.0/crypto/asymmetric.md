# Asymmetric Cryptography

Asymmetric cryptography (also called public-key cryptography) is a cryptographic system that uses multiple keys&mdash;usually a "public" and "private" key.

Read more about [public-key cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography) on Wikipedia.

## RSA

A popular asymmetric cryptography algorithm is RSA. RSA has two key types: public and private.

RSA can create signatures from any data using a private key. 

```swift
let privateKey: String = ...
let signature = try RSA.SHA512.sign("vapor", key: .private(pem: privateKey))
```

!!! info
	Only private keys can _create_ signatures.

These signatures can be verified against the same data later using either the public or private key.

```swift
let publicKey: String = ...
try RSA.SHA512.verify(signature, signs: "vapor", key: .public(pem: publicKey)) // true
```

If RSA verifies that a signature matches input data for a public key, you can be sure that whoever generated that signature had access to that key's private key.

### Algorithms

RSA supports any of the Crypto module's [`DigestAlgorithm`](https://api.vapor.codes/crypto/latest/Crypto/Classes/DigestAlgorithm.html).

```swift
let privateKey: String = ...
let signature512 = try RSA.SHA512.sign("vapor", key: .private(pem: privateKey))
let signature256 = try RSA.SHA256.sign("vapor", key: .private(pem: privateKey))
```
