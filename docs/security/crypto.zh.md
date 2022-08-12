# 加密

Vapor 中包含 [SwiftCrypto](https://github.com/apple/swift-crypto/) 库，这是苹果 CryptoKit 库的 Linux 兼容端口。SwiftCrypto 还没有公开一些额外的加密 API，比如 [Bcrypt](https://en.wikipedia.org/wiki/Bcrypt) 和 [TOTP](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm)。

## SwiftCrypto

Swift 的 `Crypto` 库实现了苹果的 CryptoKit API。因此，[CryptoKit 文档](https://developer.apple.com/documentation/cryptokit)和 [WWDC 演讲](https://developer.apple.com/videos/play/wwdc2019/709)是学习 API 的绝佳资源。

导入 Vapor，即可使用这些 API。

```swift
import Vapor

let digest = SHA256.hash(data: Data("hello".utf8))
print(digest)
```

CryptoKit 支持下列哈希算法：

- 哈希：`SHA512`, `SHA384`, `SHA256`
- 消息验证码：`HMAC`
- 密码：`AES`, `ChaChaPoly`
- 公钥密码：`Curve25519`, `P521`, `P384`, `P256`
- 不安全的哈希: `SHA1`, `MD5`

## Bcrypt

Bcrypt 是一种密码哈希算法，它使用一个随机的盐来确保对相同的密码进行多次哈希不会得到相同的摘要。

Vapor 提供了一个 `Bcrypt` 类型用于哈希和密码比较。

```swift
import Vapor

let digest = try Bcrypt.hash("test")
```

因为 Bcrypt 使用了盐，所以不能直接比较密码哈希值。明文密码和现有摘要必须同时进行验证。

```swift
import Vapor

let pass = try Bcrypt.verify("test", created: digest)
if pass {
	// 密码和摘要匹配。
} else {
	// 错误密码。
}
```

使用 Bcrypt 密码登录可以根据电子邮件或用户名从数据库中获取用户的密码摘要来实现。然后根据提供的明文密码验证已知的摘要。

## OTP

Vapor 支持 HOTP 和 TOTP 一次性密码。OTP 使用 SHA-1、SHA-256 和 SHA-512 哈希函数，可以提供六、七或八位数的输出。OTP 通过生成一次性人类可读密码来提供身份验证。为此，各方首先就对称密钥达成一致，该密钥必须始终保密，以维护生成密码的安全性。

#### HOTP

HOTP 是一种基于 HMAC 签名的 OTP。除了对称密钥之外，双方还约定了一个计数器，这是一个为密码提供唯一性的数字。每次尝试后，计数器都会增加。

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)
let code = hotp.generate(counter: 25)

// 或者使用静态生成函数
HOTP.generate(key: key, digest: .sha256, digits: .six, counter: 25)
```

#### TOTP

TOTP 是 HOTP 的基于时间的变体。它的工作原理基本相同，但不是简单的计数器，而是使用当前时间来生成唯一性。为了补偿由不同步的时钟、网络延迟、用户延迟和其他混杂因素引入的不可避免的偏差，生成的 TOTP 代码在指定的时间间隔（最常见的是30秒）内保持有效。

```swift
let key = SymmetricKey(size: .bits128)
let totp = TOTP(key: key, digest: .sha256, digits: .six, interval: 60)
let code = totp.generate(time: Date())

// 或者使用静态生成函数
TOTP.generate(key: key, digest: .sha256, digits: .six, interval: 60, time: Date())
```

#### Range

OTP 在提供验证和非同步计数器方面非常有用。两种 OTP 实现都能够生成一个具有容错性的 OTP。

```swift
let key = SymmetricKey(size: .bits128)
let hotp = HOTP(key: key, digest: .sha256, digits: .six)

// 生成一个正确计数器窗口
let codes = hotp.generate(counter: 25, range: 2)
```

上面的示例允许边距为2，这意味着 HOTP 将计算计数器值为`23...27`，所有这些代码都会被返回。

!!! 警告
	注意：使用的误差范围越大，攻击者采取行动的时间和自由度就越多，从而降低了算法的安全性。
