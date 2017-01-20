---
currentMenu: guide-hash
---

# Hash

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Vapor makes hashing strings easy.
Vapor 使哈希字符串变得容易。


## Example

获取哈希后一个字符串，可以使用 `Droplet` 的 `hash` 类。

```swift
let hashed = drop.hash.make("vapor")
```

## SHA2Hasher

默认 Vapor 使用 256 bit 的 SHA2Hasher。你可以给 `Droplet` 一个不同的哈希器（hasher）去改变它。

```swift
let sha512 = SHA2Hasher(variant: .sha512)

let drop = Droplet(hash: sha512)
```

### Protocol

你也可以创建你自己的哈希器（hasher）。你仅仅需要实现 `Hash` 协议。

```swift
public protocol Hash: class {
    var key: String { get set }
    func make(_ string: String) -> String
}
```
