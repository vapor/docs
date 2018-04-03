# Cipher Algorithms

Ciphers allow you to encrypt plaintext data with a key yielding ciphertext. This ciphertext can be later decrypted by the same cipher using the same key.

Read more about [ciphers](https://en.wikipedia.org/wiki/Cipher) on Wikipedia.

## Encrypt

Use the global convenience variables for encrypting data with common algorithms.

```swift
let ciphertext = try AES128.encrypt("vapor", key: "secret")
print(ciphertext) /// Data
```

## Decrypt

Decryption works very similarly to [encryption](#encrypt). The following snippet shows how to decrypt the ciphertext from our previous example.

```swift
let plaintext = try AES128.decrypt(ciphertext, key: "secret")
print(plaintext) /// "vapor"
```

See the Crypto module's [global variables](https://api.vapor.codes/crypto/latest/Crypto/Global%20Variables.html#/Ciphers) for a list of all available cipher algorithms.

## Streaming

Both encryption and decryption can work in a streaming mode that allows data to be chunked. This is useful for controlling memory usage while encrypting large amounts of data.

```swift
let key: Data // 16-bytes
let aes128 = Cipher(algorithm: .aes128ecb)
try aes128.reset(key: key, mode: .encrypt)
var buffer = Data()
try aes128.update(data: "hello", into: &buffer)
try aes128.update(data: "world", into: &buffer)
try aes128.finish(into: &buffer)
print(buffer) // Completed ciphertext
```
