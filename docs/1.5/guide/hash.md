---
currentMenu: guide-hash
---

# Hash

Vapor makes hashing strings easy.

## Example

To hash a string, use the `hash` class on `Droplet`.

```swift
let hashed = drop.hash.make("vapor")
```

## SHA2Hasher

By default, Vapor uses a SHA2Hasher with 256 bits. You can change this by giving the `Droplet` a different hasher.

```swift
let sha512 = SHA2Hasher(variant: .sha512)

let drop = Droplet(hash: sha512)
```

### Protocol

You can also create your own hasher. You just need to conform to the `Hash` protocol.

```swift
public protocol Hash: class {
    var key: String { get set }
    func make(_ string: String) -> String
}
```
