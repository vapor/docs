# Hash

Hashing is a one way method of converting arbitrary data into a fixed size format. Unlike ciphers, data that is hashed cannot be retrieved from the resulting digest. Hashes can be used to create keys, file identifiers, or store credentials.

<img alt="Hash function diagram" src="//upload.wikimedia.org/wikipedia/commons/thumb/5/58/Hash_table_4_1_1_0_0_1_0_LL.svg/480px-Hash_table_4_1_1_0_0_1_0_LL.svg.png" width="240" height="184">

> Hash function diagram from [Wikipedia](https://en.wikipedia.org/wiki/Hash_function).

!!! warning
    Avoid storing password hashes if possible. If you must, please make sure to research the state of the art before continuing.

## Make

To hash a string, use the `hash` property on `Droplet`.

```swift
let digest = try drop.hash.make("vapor")
print(digest.makeString())
```

### Checking

Some hashing algorithms create different hash digests for the same message. Because of this, it is necessary to check your hashes using the `check` method.

```swift
let matches = try drop.hash.check("vapor", matchesHash: digest)
```

## CryptoHasher

By default, Vapor uses a SHA-256 hasher. You can change this in the configuration files or by giving the `Droplet` a different hasher.

### Configuration

`Config/droplet.json`
```json
{
    ...,
    "hash": "crypto",
    ...
}
```

`Config/crypto.json`
```json
{
    "hash": {
        "method": "sha256",
        "encoding": "hex",
        "key": "password"
    },
    ...
}
```

#### Encoding

The CryptoHasher supports three methods of encoding.

- `hex`
- `base64`
- `plain`

#### Key

Supplying a key will cause the hasher to produce _keyed_ hashes using HMAC. Some hashers require a key.

#### Supported

| Name         | Method      | Requires Key |
|--------------|-------------|--------------|
| SHA-1        | sha1        | no           |
| SHA-224      | sha224      | no           |
| SHA-256      | sha256      | no           |
| SHA-384      | sha384      | no           |
| SHA-512      | sha512      | no           |
| MD4          | md4         | no           |
| MD5          | md5         | no           |
| RIPEMD-160   | ripemd160   | no           |
| Whirlpool    | whirlpool   | yes          |
| Streebog-256 | streebog256 | yes          |
| Streebog-512 | streebog512 | yes          |
| GostR341194  | gostr341194 | yes          |

### Manual

Hashers can be swapped without the use of configuration files.

#### Hash

```swift
let hash = CryptoHasher(
    hash: .sha256,
    encoding: .hex
)

let drop = try Droplet(hash: hash)

```

#### HMAC

```swift
let hash = CryptoHasher(
    hmac: .sha256,
    encoding: .hex,
    key: "password".makeBytes()
)

let drop = try Droplet(hash: hash)
```

## BCryptHasher

BCrypt is a password hashing function that automatically incorporates salts and offers a configurable cost. The cost can be used to increase the computation required to generate a hash.

!!! seealso
    Learn more about [key stretching](https://en.wikipedia.org/wiki/Key_stretching) on Wikipedia.

### Configuration

To use the BCryptHasher change the `"hash"` key in the `droplet.json` configuration file.

`Config/droplet.json`
```json
{
    ...,
    "hash": "bcrypt",
    ...
}
```

To configure the cost, add a `bcrypt.json` file.

`Config/bcrypt.json`
```json
{
    "cost": 8
}
```

!!! tip
    You can use different BCrypt costs for production and development modes to keep password hashing fast while working on a project.

### Manual

You can manually assign a `BCryptHasher` to `drop.hash`.

```swift
let hash = BCryptHasher(cost: 8)

let drop = try Droplet(hash: hash)
```

## Advanced

### Custom

You can also create your own hasher. You just need to conform to the `Hash` protocol.

```swift
/// Creates hash digests
public protocol HashProtocol {
    /// Given a message, this method
    /// returns a hashed digest of that message.
    func make(_ message: Bytes) throws -> Bytes

    /// Checks whether a given digest was created
    /// by the supplied message.
    ///
    /// Returns true if the digest was created
    /// by the supplied message, false otherwise.
    func check(_ message: Bytes, matchesHash: Bytes) throws -> Bool
}
```
