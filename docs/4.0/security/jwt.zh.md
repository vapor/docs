# JWT

JSON Web Token (JWT) 是一种开放标准 ([RFC 7519](https://tools.ietf.org/html/rfc7519))，它定义了一种紧凑而独立的方式，用于在各方之间作为 JSON 对象安全地传输信息。此信息可以被验证和信任，因为它经过数字签名。

JWT 在 Web 应用程序中特别有用，通常用于无状态的身份认证/授权以及信息交换。你可以在上面链接的规范或 [jwt.io](https://jwt.io/introduction) 上阅读更多关于 JWT 背后原理的信息。

Vapor 通过 `JWT` 模块为 JWT 提供了一流的支持。该模块构建在 `JWTKit` 库之上，这是一个基于 [SwiftCrypto](https://github.com/apple/swift-crypto) 的 JWT 标准的 Swift 实现。JWTKit 为多种算法提供了签名者和验证者，包括 HMAC、ECDSA、EdDSA 和 RSA。

## 入门

在 Vapor 应用程序中使用 JWT 的第一步是将 `JWT` 依赖项添加到项目的 `Package.swift` 文件中：

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "my-app",
    dependencies: [
        // Other dependencies...
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            // Other dependencies...
            .product(name: "JWT", package: "jwt")
        ]),
        // Other targets...
    ]
)
```

### 配置

添加依赖项之后，你就可以开始在应用程序中使用 `JWT` 模块了。JWT 模块在 `Application` 中新增了一个 `jwt` 属性用于配置，其内部实现由 [JWTKit](https://github.com/vapor/jwt-kit) 库提供。

#### 密钥集合

`jwt` 对象带有一个 `keys` 属性，它是 JWTKit 的 `JWTKeyCollection` 的实例。该集合用于存储和管理用于签名和验证 JWT 的密钥。`JWTKeyCollection` 是一个 `actor`，这意味着对该集合的所有操作都是串行化且线程安全的。

要签名或验证 JWT，你需要向该集合添加一个密钥。这通常在 `configure.swift` 文件中完成：

```swift
import JWT

// Add HMAC with SHA-256 signer.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

这会向密钥链添加一个以 SHA-256 作为摘要算法的 HMAC 密钥，在 JWA 表示法中即为 HS256。有关可用算法的更多信息，请查看下方的[算法](#algorithms)部分。

!!! note 
    请务必将 `"secret"` 替换为实际的密钥。该密钥应妥善保管，最好放在配置文件或环境变量中。

### 签名

添加好的密钥即可用于对 JWT 进行签名。为此，你首先需要*一些东西*来签名，即一个「payload」。
这个 payload 就是一个包含你想要传输的数据的 JSON 对象。你可以通过让你的结构体遵循 `JWTPayload` 协议来创建自定义 payload：

```swift
// JWT payload structure.
struct TestPayload: JWTPayload {
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
    }

    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim

    // The "exp" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim

    // Custom data.
    // If true, the user is an admin.
    var isAdmin: Bool

    // Run any additional verification logic beyond
    // signature verification here.
    // Since we have an ExpirationClaim, we will
    // call its verify method.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

对 payload 签名是通过调用 `JWT` 模块的 `sign` 方法完成的，例如在路由处理程序中：

```swift
app.post("login") { req async throws -> [String: String] in
    let payload = TestPayload(
        subject: "vapor",
        expiration: .init(value: .distantFuture),
        isAdmin: true
    )
    return try await ["token": req.jwt.sign(payload)]
}
```

当向该端点发起请求时，它会在响应体中以 `String` 形式返回已签名的 JWT，如果一切顺利，你会看到类似这样的内容：

```json
{
   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo"
}
```

你可以使用 [`jwt.io` 调试器](https://jwt.io/#debugger)对该令牌进行解码和验证。调试器会显示 JWT 的 payload（应该是你之前指定的数据）和 header，并且你可以使用签名 JWT 所用的密钥来验证签名。

### 验证

当令牌被发送*到*你的应用程序时，你可以通过调用 `JWT` 模块的 `verify` 方法来验证该令牌的真实性：

```swift
// Fetch and verify JWT from incoming request.
app.get("me") { req async throws -> HTTPStatus in
    let payload = try await req.jwt.verify(as: TestPayload.self)
    print(payload)
    return .ok
}
```

`req.jwt.verify` 辅助函数会检查 `Authorization` 请求头中的不记名令牌。如果存在，它将解析该 JWT 并验证其签名和声明。如果这些步骤中的任何一个失败，将抛出 401 Unauthorized 错误。

通过发送以下 HTTP 请求来测试该路由：

```http
GET /me HTTP/1.1
authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2YXBvciIsImV4cCI6NjQwOTIyMTEyMDAsImFkbWluIjp0cnVlfQ.lS5lpwfRNSZDvpGQk6x5JI1g40gkYCOWqbc3J_ghowo
```

如果一切正常，将返回 `200 OK` 响应并打印 payload：

```swift
TestPayload(
    subject: "vapor", 
    expiration: 4001-01-01 00:00:00 +0000, 
    isAdmin: true
)
```

完整的身份认证流程可以在[身份认证 &rarr; JWT](authentication.zh.md#jwt)中找到。

## 算法(Algorithms)

JWT 可以使用多种算法进行签名。

要向密钥链添加密钥，以下每种算法都提供了一个 `add` 方法的重载：

### HMAC

HMAC (基于哈希的消息认证码) 是一种对称算法，使用一个密钥对 JWT 进行签名和验证。Vapor 支持以下 HMAC 算法：

- `HS256`：带有 SHA-256 的 HMAC
- `HS384`：带有 SHA-384 的 HMAC
- `HS512`：带有 SHA-512 的 HMAC

```swift
// Add an HS256 key.
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
```

### ECDSA

ECDSA (椭圆曲线数字签名算法) 是一种非对称算法，使用一对公钥/私钥对 JWT 进行签名和验证。它依赖于椭圆曲线相关的数学原理。Vapor 支持以下 ECDSA 算法：

- `ES256`：使用 P-256 曲线和 SHA-256 的 ECDSA
- `ES384`：使用 P-384 曲线和 SHA-384 的 ECDSA
- `ES512`：使用 P-521 曲线和 SHA-512 的 ECDSA

所有算法都提供公钥和私钥，例如 `ES256PublicKey` 和 `ES256PrivateKey`。你可以使用 PEM 格式添加 ECDSA 密钥：

```swift
let ecdsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

// Initialize an ECDSA key with public PEM.
let key = try ES256PublicKey(pem: ecdsaPublicKey)
```

或者生成随机密钥（对测试很有用）：

```swift
let key = ES256PrivateKey()
```

将密钥添加到密钥链：

```swift
await app.jwt.keys.add(ecdsa: key)
```

### EdDSA

EdDSA (爱德华兹曲线数字签名算法) 是一种非对称算法，使用一对公钥/私钥对 JWT 进行签名和验证。它与 ECDSA 类似，两者都依赖于 DSA 算法，但 EdDSA 基于爱德华兹曲线，这是另一族椭圆曲线，并且在性能上略有提升。不过它也更新，因此支持范围较窄。Vapor 只支持使用 `Ed25519` 曲线的 `EdDSA` 算法。

你可以使用其（base-64 编码的 `String`）坐标来创建 EdDSA 密钥，如果是公钥则用 `x`，如果是私钥则用 `d`：

```swift
let publicKey = try EdDSA.PublicKey(x: "0ZcEvMCSYqSwR8XIkxOoaYjRQSAO8frTMSCpNbUl4lE", curve: .ed25519)

let privateKey = try EdDSA.PrivateKey(d: "d1H3/dcg0V3XyAuZW2TE5Z3rhY20M+4YAfYu/HUQd8w=", curve: .ed25519)
```

你也可以生成随机密钥：

```swift
let key = EdDSA.PrivateKey(curve: .ed25519)
```

将密钥添加到密钥链：

```swift
await app.jwt.keys.add(eddsa: key)
```

### RSA

RSA (Rivest-Shamir-Adleman) 是一种非对称算法，使用一对公钥/私钥对 JWT 进行签名和验证。

!!! warning
    如你所见，RSA 密钥被置于 `Insecure` 命名空间之下，以阻止新用户使用它们。这是因为 RSA 被认为不如 ECDSA 和 EdDSA 安全，应仅出于兼容性原因使用。
    如果可能，请改用其他算法。

Vapor 支持以下 RSA 算法：

- `RS256`：带有 SHA-256 的 RSA
- `RS384`：带有 SHA-384 的 RSA
- `RS512`：带有 SHA-512 的 RSA

你可以使用 PEM 格式创建 RSA 密钥：

```swift
let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC0cOtPjzABybjzm3fCg1aCYwnx
PmjXpbCkecAWLj/CcDWEcuTZkYDiSG0zgglbbbhcV0vJQDWSv60tnlA3cjSYutAv
7FPo5Cq8FkvrdDzeacwRSxYuIq1LtYnd6I30qNaNthntjvbqyMmBulJ1mzLI+Xg/
aX4rbSL49Z3dAQn8vQIDAQAB
-----END PUBLIC KEY-----
"""

// Initialize an RSA key with public pem.
let key = try Insecure.RSA.PublicKey(pem: rsaPublicKey)
```

或者使用其各个组成部分：

```swift
// Initialize an RSA private key with components.
let key = try Insecure.RSA.PrivateKey(
    modulus: modulus, 
    exponent: publicExponent, 
    privateExponent: privateExponent
)
```

!!! warning
    该软件包不支持小于 2048 位的 RSA 密钥。

然后你可以将密钥添加到密钥集合中：

```swift
await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)
```

### PSS

除了 RSA-PKCS1v1.5 算法之外，Vapor 还支持 RSA-PSS 算法。PSS (概率签名方案) 是一种更安全的 RSA 签名填充方案。建议在可能的情况下优先使用 PSS 而非 PKCS1v1.5。

该算法仅在签名阶段有所不同，这意味着密钥与 RSA 相同，不过在将其添加到密钥集合时，你需要指定填充方案：

```swift
await app.jwt.keys.add(pss: key, digestAlgorithm: .sha256)
```

## 密钥标识符 (kid)

向密钥集合添加密钥时，你还可以指定一个密钥标识符 (kid)。这是该密钥的唯一标识符，可用于在集合中查找该密钥。

```swift
// Add HMAC with SHA-256 key named "a".
await app.jwt.keys.add(hmac: "foo", digestAlgorithm: .sha256, kid: "a")
```

如果你不指定 `kid`，该密钥将被指定为默认密钥。

!!! note
    如果你添加另一个不带 `kid` 的密钥，默认密钥将会被覆盖。

在对 JWT 签名时，你可以指定要使用的 `kid`：

```swift
let token = try await req.jwt.sign(payload, kid: "a")
```

而在验证时，`kid` 会自动从 JWT 的 header 中提取出来，并用于在集合中查找相应的密钥。`verify` 方法上还有一个 `iteratingKeys` 参数，用于指定当找不到对应的 `kid` 时，是否遍历集合中的所有密钥。

## 声明(Claims)

Vapor 的 JWT 包包括几个用于实现常见 [JWT 声明](https://tools.ietf.org/html/rfc7519#section-4.1)的辅助函数。

|声明|类型|验证方法|
|---|---|---|
|`aud`|`AudienceClaim`|`verifyIntendedAudience(includes:)`|
|`exp`|`ExpirationClaim`|`verifyNotExpired(currentDate:)`|
|`jti`|`IDClaim`|n/a|
|`iat`|`IssuedAtClaim`|n/a|
|`iss`|`IssuerClaim`|n/a|
|`locale`|`LocaleClaim`|n/a|
|`nbf`|`NotBeforeClaim`|`verifyNotBefore(currentDate:)`|
|`sub`|`SubjectClaim`|n/a|

所有声明都应该在 `JWTPayload.verify` 方法中进行验证。如果声明有特殊的验证方法，你可以使用它。否则，使用 `value` 访问声明的值并检查它是否有效。

## JWK

JSON Web Key (JWK) 是一种表示密钥的 JSON 数据结构 ([RFC7517](https://datatracker.ietf.org/doc/html/rfc7517))。这些密钥通常用于向客户端提供用于验证 JWT 的密钥。

例如，Apple 将他们的 Sign in with Apple JWKS 托管在以下 URL 中。

```http
GET https://appleid.apple.com/auth/keys
```

Vapor 提供了将 JWK 添加到密钥集合的工具：

```swift
let privateKey = """
{
    "kty": "RSA",
    "d": "\(rsaPrivateExponent)",
    "e": "AQAB",
    "use": "sig",
    "kid": "1234",
    "alg": "RS256",
    "n": "\(rsaModulus)"
}
"""

let jwk = try JWK(json: privateKey)
try await app.jwt.keys.use(jwk: jwk)
```

这会将该 JWK 添加到密钥集合中，之后你就可以像使用其他密钥一样用它来签名和验证 JWT。

### JWKs

如果你有多个 JWK，你同样可以将它们添加进来：

```swift
let json = """
{
    "keys": [
        {"kty": "RSA", "alg": "RS256", "kid": "a", "n": "\(rsaModulus)", "e": "AQAB"},
        {"kty": "RSA", "alg": "RS512", "kid": "b", "n": "\(rsaModulus)", "e": "AQAB"},
    ]
}
"""

try await app.jwt.keys.use(jwksJSON: json)
```

## 发行商(Vendors)

Vapor 提供了用于处理来自以下热门发行商的 JWT 的 API。

### Apple

首先，配置你的 Apple 应用程序标识符。

```swift
// Configure Apple app identifier.
app.jwt.apple.applicationIdentifier = "..."
```

然后，使用 `req.jwt.apple` 辅助函数获取并验证 Apple JWT。

```swift
// Fetch and verify Apple JWT from Authorization header.
app.get("apple") { req async throws -> HTTPStatus in
    let token = try await req.jwt.apple.verify()
    print(token) // AppleIdentityToken
    return .ok
}
```

### Google

首先，配置你的 Google 应用标识符和 G Suite 域名。

```swift
// Configure Google app identifier and domain name.
app.jwt.google.applicationIdentifier = "..."
app.jwt.google.gSuiteDomainName = "..."
```

然后，使用 `req.jwt.google` 辅助函数获取并验证 Google JWT。

```swift
// Fetch and verify Google JWT from Authorization header.
app.get("google") { req async throws -> HTTPStatus in
    let token = try await req.jwt.google.verify()
    print(token) // GoogleIdentityToken
    return .ok
}
```

### Microsoft

首先，配置你的 Microsoft 应用程序标识符。

```swift
// Configure Microsoft app identifier.
app.jwt.microsoft.applicationIdentifier = "..."
```

然后，使用 `req.jwt.microsoft` 辅助函数获取并验证 Microsoft JWT。

```swift
// Fetch and verify Microsoft JWT from Authorization header.
app.get("microsoft") { req async throws -> HTTPStatus in
    let token = try await req.jwt.microsoft.verify()
    print(token) // MicrosoftIdentityToken
    return .ok
}
```
